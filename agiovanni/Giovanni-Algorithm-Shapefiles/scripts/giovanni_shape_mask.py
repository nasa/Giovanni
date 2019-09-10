#!/bin/env python
"""
####################################################################
NAME
g4_shape_mask.py - Mask Data According to Shapefile Shape

DESCRIPTION
This is a step in the workflow for generating and applying masks built
from shapefile shapes. This enables most services down the line from
even being aware that a shape was selected.

If this script is called without an -S option, it simply copies
the in-file to the out-file.

SYNOPSIS
Usage: giovanni_shape_mask.py [options]

OPTIONS
  -S               Shape identifier, in $shapefile/$shape format.
  --bbox           Users bounding box
  --in-file        Input manifest XML file
  --out-file       Output manifest XML file
  --service        Service name. This is necessary because some
                   services require special behaviour
  --mask-type      LATITUDE_WEIGHTING_FUNCTION - see AreaAverageMode()
  --silent         Do not write to STDOUT unless an error occurs.

DEPENDENCY
agiovanni, netCDF4, numpy

AUTHORS
Daniel da Silva, 10/27/2014, Initial version
Michael A Nardozzi 05/25/2016, Version 2 with landsea mask support
Richard Strub      05/25/2016
Richard Strub      03/11/2018  Supports Multi-File ArAvTs

VERSION
2.0
####################################################################
"""

__author__ = 'Daniel da Silva <Daniel.daSilva@nasa.gov>'
__author__ = 'Michael A Nardozzi <michael.a.nardozzi@nasa.gov>'

import glob
import logging
import optparse
import os
import shutil
import sys
import tempfile
import time
import zipfile
import re
import fcntl
import subprocess

import netCDF4
import numpy
import simplejson as json

import agiovanni.cfg
import agiovanni.geo
import agiovanni.gdal
import agiovanni.mfst
import agiovanni.nco
import agiovanni.prov
import xml.etree.cElementTree as et
import agiovanni.intersect as intersect
from agiovanni.cfg import ConfigEnvironment

# Name of the variable in the output files to hold the mask
MASK_VAR_NAME = 'shape_mask'
# Prefix to append to masked files. Ex, scrubbedMask.scrubbed.etc.
MASKED_FILE_PREFIX = 'shapeMasked'
# Whether the GDAL any touch option (-at) should be enabled. When
# enabled, any grid cell intersecting any part of the shape will be
# included. When disabled, the shape must intersect 50% of the cell.
ANY_TOUCH_ENABLED = True
# Message displayed on the status bar at the beginning of this step.
STATUS_MSG = "Subsetting according to shape"
# Format string (strftime) used to create prefix of each line in
# the mfst.%.log file. $MS must be manually replaced with the
# millisecond count, being three digits between 000 and 999
LOG_FORMATTER = "%Y-%m-%d %H:%M:%S,$MS - [INFO ] - shape_mask -"
# Step label to be placed in the provenance. Displays in the frontend
# on the lineage.
PROV_STEP_LABEL = 'Shape Subsetting'
# Name of the mask file to place in the provenance.
PROV_MASK_FILE = 'shapeMask.nc'

# Open and obtain a lock file for PROV_MASK_FILE which is unique to
# each session. We need this lock so that concurrent programs do
# not write to the same mask file (shapeMask.nc)
fh_shape = os.path.join(os.getcwd(), PROV_MASK_FILE)
fh = os.path.join(os.getcwd(), PROV_MASK_FILE + '.lock')

# Check to see if the burned mask file exists, If it does then
# we want to open a lock file and create an exclusive lock

if os.path.exists(fh_shape):
    try:
        fd = os.open(fh, os.O_WRONLY | os.O_CREAT | os.O_TRUNC)
    except IOError:
        log.error('Failed to open lock file, aborting')
        sys.exit(-1)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
    except IOError:
        sys.stderr.write("Error: Failed to create an exclusive lock")
        log.error('Failed to create an exclusive lock, aborting.')
        sys.exit(-1)
else:
    fd = ""  # The burned shape mask did not exist so we move on


class GiovanniShapeMaskExeception(Exception):

    """Base exception for excepts in this module."""


class ParseCLIArgsError(GiovanniShapeMaskExeception):

    """Exception thrown when there was an error parsing cli args."""


class ProgramMode(object):

    """A base-class for a mode of program containing a main()
    function to use.

    This class is not instantiated.
    """

    def main(self, options, config_env):
        """Main function for the program's mode.

        Args
          options, an object providing the command line arguments
          config_env, an instance of agiovanni.cfg.ConfigEnvironment
            to access the installation config.
        Returns
          mask file path (string) used in the computation
        """
        raise NotImplementedError

    def transform_to_contrib_space(self, source, dest, res_factor):
        """Transforms a 2D mask on a hi-res grid to a 3D mask on a
        low-res grid.

        The number of elements is invariant under this transformation.
        Only the shape is changed.

        This additional dimension can be thought of as a vertical column
        associated with each cell. Each vertical column has a 1-1 mapping
        mapping between it and the cells in the hi-res mask that
        contributed to it.

        Args
          source, file name of the existing mask file at hi-res
          dest, the file name to write the new mask to
          res_factor, integer ratio of hi-res to low-res (same for
            both dimensions).
        Raises
          agiovanni.nco.NCOError, an error occured in the NCO call.
        """
        template_vars = {
            'resFactor': res_factor,
        }

        script_contents = """
        // Variables imported from Python
        *resFactor = %(resFactor)d;

        // Create new dimensions for latitude, longitude, and
        // and contrib.
        *nlat = $lat.size / resFactor;
        *nlon = $lon.size / resFactor;

        defdim("lat_low_res", nlat);
        defdim("lon_low_res", nlon);
        defdim("contrib", resFactor*resFactor);

        lat_low_res@units="degrees_north";
        lon_low_res@units="degrees_east";

        lat_low_res[$lat_low_res] = 0.;
        lon_low_res[$lon_low_res] = 0.;

        // Perform the transformation.
        *lat0 = resFactor / 2;
        *lon0 = resFactor / 2;

        lat_low_res(:) = lat(lat0::resFactor);
        lon_low_res(:) = lon(lon0::resFactor);

        *lat_offset = (lat(1) - lat(0)) / 2;
        *lon_offset = (lon(1) - lon(0)) / 2;

        for (*i = 0; i < $lat_low_res.size; i++) {
          lat_low_res(i) = lat_low_res(i) - lat_offset;
        }

        for (*i = 0; i < $lon_low_res.size; i++) {
          lon_low_res(i) = lon_low_res(i) - lon_offset;
        }

        b[$lat_low_res, $lon_low_res, $contrib] = 0.0f;

        for (*i = 0; i < resFactor; i++) {
          for (*j = 0; j < resFactor; j++) {
            *contribIdx = i * resFactor + j;
            b(:, :, contribIdx) = Band1(i::resFactor, j::resFactor);
          }
        }
        """ % template_vars

        _, script_path = tempfile.mkstemp()

        script_file = open(script_path, 'w')
        script_file.write(script_contents)
        script_file.close()

        try:
            agiovanni.nco.run_script(script_path, source, dest)
        finally:
            os.remove(script_path)

        # The NCO script introduct the new dimensions lat_low_res and
        # lon_low_res, and left the old dims and b. Clean this up.
        dim_name_map = {
            'lat_low_res': 'lat',
            'lon_low_res': 'lon',
        }

        var_name_map = {
            'b': MASK_VAR_NAME,
        }

        agiovanni.nco.remove_dims(dest, dest, ('lat', 'lon'), overwrite=True)
        agiovanni.nco.rename_dims(dest, dest, dim_name_map, rename_vars=True,
                                  overwrite=True)

        agiovanni.nco.rename_vars(dest, dest, var_name_map, overwrite=True)


# We now have two kinds of area averaged (weighted) masking:
# 1. Create the mask and mask the files.  (AreaAverageModeApply)
# 2. Create the mask and let the ScienceCommand script (later) mask the files. (AreaAverageModePrep)
# This parent class contains the shared functions.
# Here ProgramMode just means whether or not to do weighting
class AreaAva(ProgramMode):

    input_res = -1
    prov_dir = ""
    mfst_id = ""

    def establish_bounds(self, options, config_env):

        AreaAva.mfst_id, input_files = agiovanni.mfst.read_file_list(
            options.in_file)
        AreaAva.input_res = Util.get_netcdf_resolution(input_files[0])

        AreaAva.res_factor = config_env.getAATSDownSamplingFactor()
        AreaAva.prov_dir = config_env.getShapeFileProvisionedDir()
        shape_bounds = Util.get_shape_bounds(
            AreaAva.prov_dir, *options.S.split('/'))
        subset_bounds = shape_bounds.extend(
            AreaAva.input_res.lon, AreaAva.input_res.lat)
        return input_files, subset_bounds

    def create_weighted_mask(self, options, output_files, subset_bounds):
        # Convert shape polygon to raster data in NetCDF format. This is
        # at a res a constant factor higher than the data's res (same
        # constant in both dimensions).
        #
        # The bounds we provide to gdal.rasterize are interpreted as the
        # grid centers of the edges of the resultant data.
        #
        # The diagram below is taken at mid-latitude. Each of the smaller
        # squares is a cell at hi-res, together covering one cell at low-
        # res.
        #
        #  +---+---+---+---+       D: the center of the right-most cell of
        #  |   |   |   |   |          the data, at low-res
        #  +---+---+---+---+       M: the center of the right-most cell of
        #  |   |   |   |   |          the mask, at hi-res
        #  +---+---D---+-M-+
        #  |   |   |   |   |
        #  +---+---+---+---+
        #  |   |   |   |   |
        #  +---+---+---+---+
        #
        mask_res = AreaAva.input_res.scale(1. / AreaAva.res_factor)
        data_bounds = Util.get_netcdf_bounds(output_files[0])
        tmp = float(AreaAva.res_factor - 1) / 2
        mask_bounds = agiovanni.geo.Bounds(
            data_bounds.west - tmp * mask_res.lon,
            data_bounds.south - tmp * mask_res.lat,
            data_bounds.east + tmp * mask_res.lon,
            data_bounds.north + tmp * mask_res.lat,
        )

        shapefile, shape_id = options.S.split('/')
        shapefile_path, shapefile_suffix = Util.getCorrectSuffixShapeName(
            AreaAva.prov_dir, shapefile)
        mask_name = Util.get_first_step_filename("shapeMask.nc")

        kwargs = {}
        if options.silent:
            kwargs['stdout'] = open('/dev/null', 'w')

        # If shapefile is of type *.shp, then we need to rasterize the data
        # file
        if (shapefile_suffix == "shp"):
            agiovanni.gdal.rasterize(shapefile_path, mask_name,
                                     shape_id,
                                     mask_res, mask_bounds,
                                     any_touch=ANY_TOUCH_ENABLED,
                                     **kwargs)

        # Else we have a NetCDF file and we don't need to rasterize the data
        # file
        elif (shapefile_suffix == "nc"):
            AreaAva.res_factor = 1  # already have an nc mask
            os.system("cp  " + shapefile_path + " " + mask_name)
            mask_res = Util.get_netcdf_resolution(mask_name)
            if (Util.compare_resolutions(AreaAva.input_res, mask_res)):
                bounds_str = str(subset_bounds.west) + \
                    "," + str(subset_bounds.south) + "," + \
                    str(subset_bounds.east) + "," + str(subset_bounds.north)
                # create regridder.xml
                # change input_res to factored res:
                # assign proper mask resolution:
                # regrid_lats4d needs time: add it if mask doesn't have it:
                mask_name = Util.check_for_time_dim(mask_name)
                # create input file for regrid_lats4d
                mask_regrid_name = Util.get_first_step_filename(
                    "mask_regrid.xml")
                Util.createMaskRegriddingXML(
                    AreaAva.input_res,
                    mask_res,
                    output_files[0],
                    mask_name,
                    AreaAva.mfst_id,
                    mask_regrid_name)

                # Regrid the mask
                old_mask_name, mask_name = Util.get_next_step_filename(
                    mask_name)
                if (os.system("regrid_lats4d.pl  -f " + mask_regrid_name + " -b " +
                              bounds_str + " -outfile " + mask_name + " -o " + os.getcwd())):
                    raise NotImplementedError(
                        "Regrid failed:  %s" %
                        shapefile_suffix)

            # Code below doesn't want time in mask:
            if (not os.system("ncdump -v time " + mask_name + " > /dev/null")):
                old_mask_name, mask_name = Util.get_next_step_filename(
                    mask_name)
                cmd = "ncwa  -a time " + old_mask_name + " " + mask_name
                if (os.system(cmd) != 0):
                    raise NotImplementedError(
                        "averaging out time failed:  %s " %
                        cmd)

            # next step is expecting Band1
            agiovanni.nco.rename_vars(
                mask_name, mask_name, {
                    'shape_mask': 'Band1'}, overwrite=True)
        else:
            raise NotImplementedError(
                "Do not know how to handle shape suffix:  %s" %
                shapefile_suffix)

        # Transform the mask to a 3D mask where the lat and lon dimensions
        # correspond to a lower-res grid. The third dimension, 'contrib',
        # spans the hi-res cells that contributed to the corresponding
        # cell in low-res.

        # This transform_to_contrib thing changes the coordinates in the land/sea mask case.
        # calc_area_stats just uses the matrix and doesn't care what the coordinates were.
        # New NCO code does care and so this way we preserve the coordinates of the
        # original data just as grid_lats4d.pl went to great efforts to do
        if (AreaAva.res_factor != 1):  # nc lats4d case:
            old_mask_name, mask_name = Util.get_next_step_filename(mask_name)
            AreaAva().transform_to_contrib_space(old_mask_name, mask_name,
                                                 AreaAva.res_factor)

            # Average the mask in contrib space along the contrib dim,
            # generating a 2D mask that is on the data's grid.
            old_mask_name, mask_name = Util.get_next_step_filename(mask_name)
            agiovanni.nco.average(old_mask_name, mask_name, ('contrib',))

        else:
            var_name_map = {
                'Band1': MASK_VAR_NAME,
            }
            agiovanni.nco.rename_vars(
                mask_name, mask_name, var_name_map, overwrite=True)
            agiovanni.nco.remove_dims(
                mask_name, mask_name, ('time'), overwrite=True)

          # Weight the mask cell values by the cosine of their latitude
        old_mask_name, mask_name = Util.get_next_step_filename(mask_name)
        agiovanni.nco.inline_script('*d2r=acos(-1.)/180.; %s = cos(lat*d2r)*%s'
                                    % (MASK_VAR_NAME, MASK_VAR_NAME),
                                    old_mask_name, mask_name)

        # Before appending mask to output files, ensure that they have the
        # same spatial shape. NCO will silently corrupt the data otherwise.
        Util.assert_same_shape(mask_name, MASK_VAR_NAME,
                               output_files[0], AreaAva.mfst_id,
                               'Mask shape %(shape_a)s != data shape %(shape_b)s')

        # TimeAverageMap files need to be cropped to the bbox of the shape
        # We need the mfst_id in case we are doing two different variables with
        # different spatial resolutions
        CROPPED_MASK = 'croppedMask_' + AreaAva.mfst_id + '.nc'
        # Create AreaAverageTimeSeries Crop File
        cropped_mask_path = os.path.join(os.getcwd(), CROPPED_MASK)
        # Using mask bounds here seems to keep the correct resolution
        if not os.path.exists(cropped_mask_path):
            agiovanni.nco.subset(mask_name, CROPPED_MASK, mask_bounds)
        return CROPPED_MASK 


class DefaultMode(ProgramMode):

    """Contains the default main() execution sequence.

    A mask is generated at the data's resolution, and then applied
    to the data. This is for algorithms that do not need any
    information about the mask, and can function just fine without
    knowing a shape was selected.
    """

    def main(self, options, config_env):
        """Main function for default mode"""
        # Subset the data to the the size of the shape's bounding box. This
        # speeds up the computation drastically. TODO(ddasilva): this can be
        # parallized, revisit when improving performance.
        mfst_id, input_files = agiovanni.mfst.read_file_list(options.in_file)
        prov_dir = config_env.getShapeFileProvisionedDir()
        input_res = Util.get_netcdf_resolution(input_files[0])
        shape_bounds = Util.get_shape_bounds(prov_dir, *options.S.split('/'))
        subset_bounds = shape_bounds.extend(input_res.lon, input_res.lat)

        output_files = []

        for input_file in input_files:
            basename = os.path.basename(input_file)
            basename = '%s.%s' % (MASKED_FILE_PREFIX, basename)
            output_file = os.path.join(os.getcwd(), basename)

            agiovanni.nco.subset(input_file, output_file, subset_bounds)
            output_files.append(output_file)

        # Convert shape polygon to raster data in NetCDF format.
        data_bounds = Util.get_netcdf_bounds(output_files[0])
        shapefile, shape_id = options.S.split('/')
        shapefile_path, shapefile_suffix = Util.getCorrectSuffixShapeName(
            prov_dir, shapefile)
        mask_name = Util.get_first_step_filename("shapeMask.nc")

        kwargs = {}
        if options.silent:
            kwargs['stdout'] = open('/dev/null', 'w')

        # If shapefile is of type *.shp, then we need to rasterize the data
        # file
        if (shapefile_suffix == "shp"):
            agiovanni.gdal.rasterize(
                shapefile_path,
                mask_name,
                shape_id,
                input_res,
                data_bounds,
                any_touch=ANY_TOUCH_ENABLED,
                **kwargs)
            agiovanni.nco.rename_vars(
                mask_name, mask_name, {
                    'Band1': 'shape_mask'}, overwrite=True)
        # Else we have a NetCDF file and we don't need to rasterize the data
        # file
        elif (shapefile_suffix == "nc"):
            os.system("cp  " + shapefile_path + " " + mask_name)
            mask_res = Util.get_netcdf_resolution(mask_name)
            # For the NetCDF case, we need to check to see if the input file and mask are of the same resolution
            # If resolutions are identical, then we do not need to regrid to
            # the resolution of the input file
            if (Util.compare_resolutions(input_res, mask_res)):
                # Somewhere else they may do this better:
                bounds_str = str(data_bounds.west) + "," + str(data_bounds.south) + \
                    "," + str(data_bounds.east) + "," + str(data_bounds.north)

                # Call the sub-routine to check if shape mask has time dimension
                # because regrid_lats4d.pl needs time
                mask_name = Util.check_for_time_dim(mask_name)

                # create regridder.xml
                mask_regrid_name = Util.get_first_step_filename(
                    "mask_regrid.xml")
                Util.createMaskRegriddingXML(
                    input_res,
                    mask_res,
                    output_files[0],
                    mask_name,
                    mfst_id,
                    mask_regrid_name)

                # Regrid the mask
                old_mask_name, mask_name = Util.get_next_step_filename(
                    mask_name)
                if (os.system("regrid_lats4d.pl  -f " + mask_regrid_name + " -b " +
                              bounds_str + " -outfile " + mask_name + " -o " + os.getcwd())):
                    raise NotImplementedError(
                        "Regrid failed:  %s" %
                        shapefile_suffix)

                old_mask_name, mask_name = Util.get_next_step_filename(
                    mask_name)
                cmd = "ncap2 -s 'shape_mask= ( shape_mask >= 0.1 )' " + \
                    old_mask_name + " " + mask_name
                if (os.system(cmd)):
                    raise NotImplementedError("nco command failed:  %s" % cmd)

        else:
            raise NotImplementedError(
                "Do not know how to handle shape suffix:  %s" %
                shapefile_suffix)

        # Before appending mask to output files, ensure that they have the
        # same spatial shape. NCO will silently corrupt the data otherwise.
        # You need a subrouttine here to create in_regrid.xml

        Util.assert_same_shape(mask_name, MASK_VAR_NAME,
                               output_files[0], mfst_id,
                               'Mask shape %(shape_a)s != data shape %(shape_b)s')

        # Reshape the mask to the same shape as the data and add it to the
        # file. Reshaping is necessary to efficiently apply the mask.
        for output_file in output_files:
            self.apply_mask(mask_name, output_file, mfst_id)

        # Write output files, complete
        agiovanni.mfst.write_file_list(options.out_file,
                                       mfst_id,
                                       output_files)

        return mask_name

    def apply_mask(self, mask_file, data_file, var_name):
        """Apply the mask to the data file.

        This function adds the mask to the data file at the shape
        of the data, and then applies it. A variable in named
        $MASK_VAR_NAME is written to the data file.

        Args
          mask_file, the NetCDF file containing the mask
          data_file, the NetCDF file containing the data
          var_name, name of the variable in the data file
        Raises
          KeyError, variable does not exist
          RuntimeError, cannot open NetCDF file
        """
        mask_ds = netCDF4.Dataset(mask_file)
        data_ds = netCDF4.Dataset(data_file, 'a')

        mask = mask_ds.variables[MASK_VAR_NAME]
        var = data_ds.variables[var_name]

        # Add the mask to the data file at the shape of the data.
        mask_cp = data_ds.createVariable(MASK_VAR_NAME, 'f8',
                                         var.dimensions,
                                         fill_value=0)
        if len(var.shape) == 3:
            nt = var.shape[0]
            for i in range(nt):
                mask_cp[i, :, :] = mask[:]
        elif len(var.shape) == 4:
            nt = var.shape[0]
            nz = var.shape[1]
            for i in range(nt):
                for j in range(nz):
                    mask_cp[i, j, :, :] = mask[:]
        else:
            raise NotImplementedError("Do not know how to handle variable with "
                                      "shape %s" % repr(var.shape))

        # Apply the mask to the data. We take the logical not of them mask
        # because numpy considers 1 <=> masked and 0 <=> unmasked.
        np_mask = numpy.logical_not(mask_cp[:])
        var[:] = numpy.ma.masked_array(var[:], mask=np_mask)

        mask_ds.close()
        data_ds.close()


# Create the mask and apply it in this class
class AreaAverageModeApplyMask(AreaAva):

    """Contains the custom main() execution sequence for area averaged
    time series mode.

    This mode exists because area averaged time series computations,
    later in the generation of the result, require the mask to be
    unapplied and to be weighted by cos(lat).

    In this mode, the mask is generated at a higher resolution equal
    to a constant factor of the data's resolution. The mask is then
    regridded to the data's resolution with the additional property
    that the mask consists of weights in [0, 1] equal to the porportion
    of the cell covered by the shape. These mask values are weighted
    a second time by cos(lat).
    """

    def main(self, options, config_env):

        input_files, subset_bounds = AreaAva().establish_bounds(options, config_env)

        output_files = []

        for input_file in input_files:
            basename = os.path.basename(input_file)
            basename = '%s.%s' % (MASKED_FILE_PREFIX, basename)
            output_file = os.path.join(os.getcwd(), basename)

            agiovanni.nco.subset(input_file, output_file, subset_bounds)
            output_files.append(output_file)

        mask_name = AreaAva().create_weighted_mask(
            options, output_files, subset_bounds)

        for output_file in output_files:
            Util.append_variable(mask_name, output_file, MASK_VAR_NAME)

        # Write output files, complete
        agiovanni.mfst.write_file_list(options.out_file,
                                       AreaAva.mfst_id,
                                       output_files)

        return mask_name


# Create the mask and apply it later in the workflow.
class AreaAverageModePrepMask(AreaAva):

    """This version only preps the Mask for application in
    g4_area_avg_diff_time_series.py. It is in that script that
    shape_mask is added to each cube being processed and then
    used as a weight for averaging.

    see AreaAverageModeApplyMask() for additional info
    """

    def main(self, options, config_env):

        input_files, subset_bounds = AreaAva().establish_bounds(options, config_env)

        output_files = []
        prepmask_files = []

        # For new multi-file areaAveraging we are not creating a new file here
        # In the initial session case the scrubbed file and the masked file are
        # in the same directory. But in the next session case they are not.
        # So we need to preserve the whole dir
        for input_file in input_files:
            basename = os.path.basename(input_file)
            output_file = input_file

            output_files.append(input_file)

        # So that we can mask EXACTLY like before lets mask 1 file and use it:
        for input_file in input_files[:1]:
            basename = os.path.basename(input_file)
            basename = '%s.%s' % (MASKED_FILE_PREFIX, basename)
            output_file = os.path.join(os.getcwd(), basename)
            agiovanni.nco.subset(input_file, output_file, subset_bounds)
            prepmask_files.append(output_file)

        mask_name = AreaAva().create_weighted_mask(
            options, prepmask_files, subset_bounds)

        # including cropped mask in file being passed to next step
        # needs to be done carefully as Wrapper uses first and last file
        # to establish start and end time of the plot
        #output_files.insert(0,(os.path.join(os.getcwd(), mask_name)))

        # Write output files, complete
        agiovanni.mfst.write_file_list(options.out_file,
                                       AreaAva.mfst_id,
                                       output_files)

        return mask_name


class Util(object):

    """A collection of static utility functions."""

    @staticmethod
    def append_variable(netcdf_source, netcdf_dest,
                        var_name):
        """Copies a variable between files.

        Assumes the destination file has the dimensions
        needed for the variable.

        Args
          netcdf_source: file to read from
          netcdf_dest: file to write to
          variable: name of the variable in netcdf_source
        Raises
          KeyError: variable does not exist in netcdf_source
        """
        source = netCDF4.Dataset(netcdf_source)
        dest = netCDF4.Dataset(netcdf_dest, 'a')

        source_var = source.variables[var_name]  # raises KeyError
        dest_var = dest.createVariable(var_name,
                                       source_var.dtype,
                                       dimensions=source_var.dimensions)
        dest_var[:] = source_var[:]

        source.close()
        dest.close()

    @staticmethod
    def assert_same_shape(netcdf_path_a, var_name_a,
                          netcdf_path_b, var_name_b,
                          message):
        """Assert two variables in two files have the same shape.

        Args
          netcdf_path_a, path to first NetCDF file
          var_name_a, name of first variable
          netcdf_path_b, path to second NetCDF file
          var_name_b, name of of second variable
        Raises
          AssertionError, the assertion failed
        """
        shape_a = Util.get_netcdf_shape(netcdf_path_a, var_name_a)
        shape_a = Util._get_spatial_part_of_shape(shape_a)

        shape_b = Util.get_netcdf_shape(netcdf_path_b, var_name_b)
        shape_b = Util._get_spatial_part_of_shape(shape_b)

        assert shape_a == shape_b, message % {
            'shape_a': repr(shape_a),
            'shape_b': repr(shape_b),
        }

    @staticmethod
    def _get_spatial_part_of_shape(shape):
        """Get only the spatial portion of an variable's array shape.

        This assumes the data originated through the Giovanni scrubber.

        Returns:
          (nlat, nlon) a tuple containing the spatial shape.
        """
        if len(shape) == 3:
            shape = shape[1:]  # exclude time dim
        elif len(shape) == 4:
            shape = shape[2:]  # exclude time + vertical dims

        return shape

    @staticmethod
    def get_first_step_filename(netcdf_path):
        return 'pid%d.00.%s' % (os.getpid(), netcdf_path)

    @staticmethod
    def deriveRegridOutputFilename(sent_mask_name):
        """Get the regrid output file name that is returned
        from regrid_lats4d.pl. We know the format so we can use
        python regex to parse and return the output file name.

        We know what the new_mask_name will be:
        old: pidXXXX.00.shapeMask.nc from get_first_step_filename
        new: regrid.00.shapeMask.nc from regrid_lats4d

        Args
          sent_mask_name, this is the shape mask name
        Returns
          Output file returned from regrid_lats4d.pl
        """
        m = re.search("pid\d+\.(\d+).shapeMask.nc", sent_mask_name)
        if m:
            stage = m.groups()[0]
            return '%s/regrid.%02d.shapeMask.nc' % (os.getcwd(), int(stage))
        raise NotImplementedError("Could not get the filename for "
                                  "path %s shape %s" % prov_dir, sent_mask_name)

    @staticmethod
    def check_for_time_dim(mask_name):
        hasTime = os.system("ncdump -v time " + mask_name + " > /dev/null")
        if (hasTime > 0):
            old_mask_name, mask_name = Util.get_next_step_filename(mask_name)
            os.system("ncecat -u time " + old_mask_name + " " + mask_name)
        return mask_name

    @staticmethod
    def get_next_step_filename(netcdf_path):
        """ 'pid321.01.shapeMask.nc' => 'pid321.02.shapeMask.nc' """
        toks = netcdf_path.split('.')
        next_num = int(toks[1]) + 1
        file_name = '.'.join([toks[0], str(next_num).zfill(2)] + toks[2:])
        return netcdf_path, file_name

    @staticmethod
    def get_netcdf_shape(netcdf_path, var_name):
        """Retrieve the shape of a variable in a NetCDF fie.

        Args
          netcdf_path, path to the NetCDF file
          var_name, the identifier for the variable in the file
        Returns
          shape, a tuple of integers.
        Raises
          KeyError, variable does not exist
          RuntimeError, cannot open NetCDF file
        """
        dataset = netCDF4.Dataset(netcdf_path)
        var = dataset.variables[var_name]
        shape = var.shape
        dataset.close()

        return shape

    @staticmethod
    def get_netcdf_bounds(netcdf_path):
        """Retrieve the bounds of a NetCDF file.

        Args
          netcdf_path, path to the NetCDF file
        Returns
          agiovanni.geo.Bounds instance, which contains
          attributes named west, east, south, north.
        Raises
          KeyError, lat or lon variable not found in file
          RuntimeError, cannot open NetCDF file
        """
        dataset = netCDF4.Dataset(netcdf_path)
        lat = dataset.variables['lat']
        lon = dataset.variables['lon']
        bounds = agiovanni.geo.Bounds(lon[0], lat[0], lon[-1], lat[-1])
        dataset.close()

        return bounds

    @staticmethod
    def get_netcdf_resolution(netcdf_path):
        """Retrieve the resolution of a NetCDF file.

        Args
          netcdf_path, path to the NetCDF file
        Returns
          agiovanni.geo.Resolution instance whcih contains
          attributes lon and lat.
        Raises
          KeyError, lat or lon variable not found in file
          RuntimeError, cannot open NetCDF file
        """
        dataset = netCDF4.Dataset(netcdf_path)

        lat = dataset.variables['lat']
        lat_res = lat[1] - lat[0]
        lon = dataset.variables['lon']
        lon_res = lon[1] - lon[0]

        dataset.close()

        return agiovanni.geo.Resolution(lon_res, lat_res)

    @staticmethod
    def compare_resolutions(input_res, mask_res):
        """Compare resolution of shape mask versus data file

        Args
          input_res, resolution of the data file
          mask_res, resolution of the shape mask (landsea mask)
        Returns
          Boolean True if input and mask resolution are the same.
          Boolean False if they are not.
        """
        if (input_res.lat != mask_res.lat):
            return True
        if (input_res.lon != mask_res.lon):
            return True
        return False

    @staticmethod
    def validate_bbox_shape_intersect(
            user_selected_bbox, infile, outfile, shape, config_env):
        """Validate the user selected bounding box intersects the shape
        bounds.

        1. First we need to find the intersection of the users bbox and
        the data bbox.
        Note: If the user does not select a bounding box, then the
        intersection is just the data extent.
        2. Once we have calculated the intersection, we will call
        agiovanni.intersects to validate the intersection (found in
        step #1 above) with the shape bounds.

        Args
          user_selected_bbox, users selected bounding box. Can be an
            empty string.
          infile, data input file used to get the data bounds.
          outfile, Output manifest file.
          shape, user selected shapefile in the form of shape/shape id.
          config_env, Configuration environment, instance of
            agiovanni.cfg.ConfigEnvironment.
        Returns
           Returns validate_bbox_shape_intersec if user bounding box intersects shape bounds.
        """

        if user_selected_bbox:
            user_bbox = '--bbox ' + user_selected_bbox
        else:
            user_bbox = ""

        mfst_id, input_files = agiovanni.mfst.read_file_list(infile)
        data_bounds = Util.get_netcdf_bounds(input_files[0])

        data_bbox = '--bbox '  \
            + str(data_bounds.west) + ','  \
            + str(data_bounds.south) + ',' \
            + str(data_bounds.east) + ','  \
            + str(data_bounds.north)

        bbox_intersect = \
            'intersectBboxes.pl ' + user_bbox + ' ' + data_bbox
        process = subprocess.Popen(bbox_intersect,
                                   stdout=subprocess.PIPE,
                                   stderr=None, shell=True)
        output = process.communicate()
        user_data_intersect = output[0] 
        
        # This is the format we want for intersects_esri() 
        data_bbox = data_bbox.replace('--bbox ','');

        prov_dir = config_env.getShapeFileProvisionedDir()
        shapefile, shape_id = shape.split('/')
        shapefile_path, shapefile_suffix = Util.getCorrectSuffixShapeName(
            prov_dir, shapefile)


        if (shapefile_suffix == "nc"):
            return 1
        else:
            # Then check this intersection: data ^ Shape
            validate_data_shape_intersect = intersect.intersects(
                data_bbox, shapefile_path, shape_id)
            # now if the nominal validate_bbox_shape_intersect is False, that is
            # if the (UserBbox ^ DataBbox) does not intersect with shape.
            # I can give a more accurate explanation.
            validate_bbox_shape_intersect = intersect.intersects(
                user_data_intersect, shapefile_path, shape_id)
        if validate_bbox_shape_intersect == False: # if (U^D)^S is false
            if user_selected_bbox:
                if validate_data_shape_intersect == True: # (D^S) is True but (U^S) is False (Newer case)
                    STATUS_MSG = 'Your selected bounding box and the selected shapefile intersects the geographical range of the data ' + \
                    'you are attempting to plot, but your selected bounding box does not intersect with the shapefile.  ' + \
                    'To remedy this error, please select a  bounding box that intersects with the shapefile .'
                else: # (D^U) is True but (D^S) is False (We don't care if (U^S) because (D^S) is False
                    STATUS_MSG = 'Your selected bounding box intersects the geographical range of the data you are attempting to plot, ' + \
                    'but the selected shapefile is outside of the data\'s geographical range.  To remedy this error, ' + \
                    'please select a shapefile with boundaries which are at least partly within the geographical range of the data.'
            else:
                STATUS_MSG = 'The geographical boundaries of the data you are using are: ' + \
                             data_bbox + '. The boundaries of the selected shapefile lie entirely outside this geographic range. ' + \
                             'A plot can only be generated if the geographic range of the data intersects with the shapefile boundary.'
            Util.get_logger(outfile, STATUS_MSG)
        return validate_bbox_shape_intersect

    @staticmethod
    def get_logger(outfile, status_msg):
        """Print status message to the log file. TODO(mnardozz):
        currently writing to file because only one status
        message script-wide; a true logging solution will be
        needed if more statuses are to be added to this script.

        Args
          oufile, Output manifest file.
          status_msg, Message displayed on the status bar.
        Raises
          RuntimeError, cannot open log file
        """
        cur_time = time.time()
        ms = int(1000 * (cur_time - int(cur_time)))
        ms = str(ms).zfill(3)

        log_fname = outfile.replace('.xml', '.log')
        log_file = open(log_fname, 'w')
        log_file.write(time.strftime(LOG_FORMATTER).replace("$MS", ms))
        log_file.write(' USER_MSG ')
        log_file.write(status_msg)
        log_file.write('\n')
        log_file.close()

    @staticmethod
    def get_shape_bounds(prov_dir, shapefile, shape_id):
        """Get bounds of a shape by reading $shapefile.json

        Args
          prov_dir, Directory of provisioned shapefiles
          shapefile, Prefix of the shapefile
          shape_id, Name of the shape in the shapefile
        Returns
          agiovanni.geo.Bounds instance
        Raises
          IOError, unable to open $shapefile.json
          KeyError, invalid $shapefile.json
        """
        json_path = os.path.join(prov_dir, '%s.json' % shapefile)
        json_file = open(json_path)
        json_contents = json.load(json_file)
        json_file.close()

        bbox = json_contents['shapes'][shape_id]['bbox']
        return agiovanni.geo.Bounds(*bbox)

    @staticmethod
    def get_shapefile_zip(options, config_env):
        """Create a zip file of all the shapefile files.

        Args
          options, Options object returned by parse_cli_args(args)
          config_env, Configuration environment, instance of
            agiovanni.cfg.ConfigEnvironment.
        Returns
          path to zip file on the system.
        """
        shapefile, _ = options.S.split('/')
        out_fpath = os.path.join(os.getcwd(), 'shapefile.zip')
        shapefile_zip = zipfile.ZipFile(out_fpath, 'w')
        prov_dir = config_env.getShapeFileProvisionedDir()

        for fname in glob.glob("%s.*" % os.path.join(prov_dir, shapefile)):
            if fname.endswith('.json'):
                # Skip the json information files; they are for internal
                # use only.
                continue
            zip_fname = os.path.join(shapefile, os.path.basename(fname))
            shapefile_zip.write(fname, zip_fname)

        shapefile_zip.close()

        return out_fpath

    @staticmethod
    def createMaskRegriddingXML(
            dataResolution, maskResolution, dataFileLoc, maskLoc, dataVarName, maskXmlName):
        """Create an xml document contatining the attribute information
           for the data file and mask file. This metadata is needed for
           further processing of the shape/mask file.

        Args
          dataResolution, this is a pre-defined location where the shape files
          maskResolution, resolution of the landsea mask. For example.. 0.10

          dateFileLoc, locations of the data file on the system
          maskLoc, location of the landsea mask file on the system
          dataVarName, data variable name
          maskXmlName, name of the XML document containing attributee info
        Returns
           xml file.
        """
        root = et.Element('data')
        firstlist = et.SubElement(
            root,
            'dataFileList',
            resolution=str(maskResolution),
            id="shape_mask",
            sdsname="shape_mask")
        et.SubElement(firstlist, 'dataFile').text = maskLoc
        secondlist = et.SubElement(
            root,
            'dataFileList',
            resolution=str(dataResolution),
            id=dataVarName,
            sdsname=dataVarName,
            gridReference="true")
        et.SubElement(secondlist, 'dataFile').text = dataFileLoc
        tree = et.ElementTree(root)
        tree.write(maskXmlName)

    @staticmethod
    def getCorrectSuffixShapeName(prov_dir, shapefile):
        """Find a valid shape or mask file and return its' path.

        Args
          prov_dir, this is a pre-defined location where the shape files
          and landsea masks are stored on the system. config_env points
          to the config file which specifies the provisioned directory
          contatining the shapefile/mask.
          shapefile, name of the shapefile. For example, gpmLandSeaMask/shp_0
          The first element (gpmLandSeaMask) is the shapefile
        Returns
          path to shapefile or shape mask on the system.
        """
        shapefile_path = '%s.shp' % os.path.join(prov_dir, shapefile)
        if (os.path.isfile(shapefile_path)):
            return shapefile_path, "shp"
        shapefile_path = '%s.nc' % os.path.join(prov_dir, shapefile)
        if (os.path.isfile(shapefile_path)):
            return shapefile_path, "nc"
        raise NotImplementedError("Could not find correct suffix for "
                                  "path %s shape %s" % prov_dir, shapefile)


def parse_cli_args(args):
    """Parse command line arguments.

    Returns
      options, an object whose attributes match the values of the
        options specified in the command line. e.g. '-e xyz' <=> options.e
    Raises
      ParseCLIArgsError, error parsing arguments.
    """
    parser = optparse.OptionParser()

    parser.add_option("-S", metavar="SHAPE", dest="S",
                      help="Shapefile identifier in $shapefile/$shape format.")
    parser.add_option("--bbox", metavar="BBOX", dest="user_bbox",
                      help="Users bounding box")
    parser.add_option("--in-file", metavar="INPUT_FILE", dest="in_file",
                      help="Input manifest file (required)")
    parser.add_option("--out-file", metavar="INPUT_FILE", dest="out_file",
                      help="Output manifest file (required)")
    parser.add_option("--service", metavar="SERVICE", dest="service",
                      help="Service. Some services require special behaviour.")
    parser.add_option("--mask-type", metavar="LATITUDE_WEIGHTING_FUNCTION", dest="mask_type",
                      help='''If == Apply, then use AreaAva:AreaAverageModeApplyMask() mask,
                            If == Prep,  then use AreaAva:AreaAverageModePrep,
                            otherwise use DefaultMode().'''
                      )

    parser.add_option("--silent", metavar="SILENT", dest="silent", action="store_true",
                      help="Do not write to STDOUT unless an error occurs.""")

    options, _ = parser.parse_args(args)

    # Check for required opts
    required_opts = [
        options.in_file,
        options.out_file,
        options.service
    ]

    if not all(required_opts):
        print required_opts
        raise ParseCLIArgsError("Required option(s) missing. See --help.")

    # Validate options
    if options.S and len(options.S.split('/')) != 2:
        raise ParseCLIArgsError("Bad -S value. Must be '$shapefile/$shape'")

    return options


def main(argv=sys.argv, config_env=None):
    """Main function of the program, calls main() in program mode.

    Args
      argv, System arguments (sys.argv by default)
      config_env, an instance of agiovanni.cfg.ConfigEnvironment
        to override the installation's config (for testing).
    """
    # Parse the command line options. If -S is not provided,
    # simply copy the input file to the output file and exit.
    options = parse_cli_args(argv)

    if not options.S:
        shutil.copy(options.in_file, options.out_file)
        return

    # Validate the users selected bbox intersects the shape bounds
    if config_env is None:
        config_env = agiovanni.cfg.ConfigEnvironment()
    validate_intersect = Util.validate_bbox_shape_intersect(
        options.user_bbox, options.in_file, options.out_file, options.S, config_env)
    if (validate_intersect == False):
        exit(1)

    # Status message for Shape Subsetting
    Util.get_logger(options.out_file, STATUS_MSG)

    # Load the mode based on the service, and run the main()
    # it provides.
    if config_env is None:
        config_env = agiovanni.cfg.ConfigEnvironment()

    if options.mask_type:
        # ArAvTs workflow applies mask later to cubes in
        # g4_area_avg_diff_time_series
        if (options.mask_type == 'Apply'):
            mode = AreaAverageModeApplyMask()
        elif (options.mask_type == 'Prep'):
            mode = AreaAverageModePrepMask()
        else:
           # perhaps some configuration was missed so we want
           # to do things the original way:
            mode = AreaAverageModeApplyMask()

    else:
        mode = DefaultMode()

    main_start = time.time()
    mask_path = mode.main(options, config_env) # returning cropped_mask
    main_end = time.time()

    # The provenance file contains input and output files. The input
    # files are copied from the --in-file argument, and the  output
    # files are copied from the manifest file mode wrote. The returned
    # mask is also added to the output files.
    prov_file_path = options.out_file.replace('mfst.', 'prov.')
    elapsed_time = main_end - main_start

    input_items = []
    output_items = []

    for file_path in agiovanni.mfst.read_file_list(options.in_file)[1]:
        input_item = agiovanni.prov.ProvItem(file_path)
        input_items.append(input_item)

    clean_mask_path = os.path.join(os.getcwd(), PROV_MASK_FILE)
    # If shapefile has already been burned, don't repeat the burning of the
    # mask file
    if not os.path.exists(clean_mask_path):
        shutil.copy(mask_path, clean_mask_path)

    if (options.mask_type == 'Prep'):
        cropped_item = agiovanni.prov.ProvItem(os.path.join(os.getcwd(),mask_path), name='Cropped Mask')
        output_items.append(cropped_item)
    else:
        mask_item = agiovanni.prov.ProvItem(clean_mask_path, name='Data Mask')
        output_items.append(mask_item)


    shape_zip_path = Util.get_shapefile_zip(options, config_env)
    shape_zip_item = agiovanni.prov.ProvItem(shape_zip_path, name='Shapefile')
    output_items.append(shape_zip_item)

    if (options.mask_type != 'Prep'):
        for file_path in agiovanni.mfst.read_file_list(options.out_file)[1]:
            output_item = agiovanni.prov.ProvItem(file_path, name='Output file')
            output_items.append(output_item)

    agiovanni.prov.write_items(prov_file_path, elapsed_time, PROV_STEP_LABEL,
                               input_items, output_items)
    # Release the PROV_MASK_FILE lock  so that concurrent programs can obtain
    # the lock. Remove the lock file
    try:
        fcntl.flock(fd, fcntl.LOCK_UN) if fd else None
    finally:
        pass  # there is no reason to delete this lock file - especially after
        # we have released control of it with the above flock call


if __name__ == '__main__':
    main()
