"""A collection of functions for utilizing GDAL.

Each of these functions may raise an GDALError if GDAL returned
a non-zero exit code  during the call.
"""
__author__ = 'Daniel da Silva <Daniel.daSilva@nasa.gov>'

import os
import subprocess
import sys


class GDALError(Exception):
    """Exception that occurs when GDAL returns a non-zero exit code.
    
    Attributes
      return_code, return code returned
    """
    def __init__(self, return_code):
        self.return_code = return_code
        
    def __repr__(self):
        return 'GDALError(%d)' % self.return_code

    __str__ = __repr__

def rasterize(shapefile_path, netcdf_path, shape_id,
              res, bounds, any_touch=True,
              stdout=sys.stdout, stderr=sys.stderr):
    """Rasterize a shapefile shape into a NetCDF array.
    
    The variable 'Band1' will be written in the output file.
    The bounds provided are western, eastern, southern, and
    northern points of the resultant NetCDF file.
    
    Args
      shapefile_path, path to the shapefile
      netcdf_path, path to the output NetCDF file
      res, agiovanni.geo.Resolution instance
      bounds, agiovanni.geo.Bounds instance
    Raises
      NCOError, NCO returned a non-zero exit code
    """
    # gdal_rasterize assumes data to have a grid reference in
    # the center. Therefore to encompass the cells, the bounds
    # must be larger than grid centers by half the resolution.
    bounds = [
        bounds.west  - res.lon/2.,
        bounds.south - res.lat/2.,
        bounds.east  + res.lon/2.,
        bounds.north + res.lon/2.,
    ]

    bounds = [str(v) for v in bounds]
    bounds = ' '.join(bounds)

    argv = [
        'gdal_rasterize',
        '-a_nodata', '0.',
        '-init', '0.',
        '-burn', '1.',
        '-where', '"gShapeID=\'%s\'"' % shape_id,
        '-te', bounds,
        '-tr', '%.5f %.5f' % (res.lon, res.lat),
        '-of', 'netCDF',
        shapefile_path,
        netcdf_path,    
    ]

    if any_touch:
        argv.append('-at')

    # TODO: do not use shell=True
    return_code = subprocess.call(' '.join(argv), stdout=stdout, stderr=stderr, shell=True)
    
    if return_code != 0:
        raise GDALError(return_code)
    
    if not os.path.exists(netcdf_path):
        raise GDALError("GDAL returned 0, but output file does not exist")
