'''
Checks to see if there is overlap between  a shape and a bounding box.
'''
__author__ = 'Christine Smit <christine.e.smit@nasa.gov>'

import ogr
from netCDF4 import Dataset
import numpy as np

from agiovanni.bbox import BBox


class IntersectError(Exception):
    '''
    Class for errors associated with calculating the intersection.
    '''
    pass


def intersects(bbox, path, shape=None):
    '''
    Returns True if the input shape intersects with bbox and False otherwise.

    bbox - bounding box string in 'west,south,east,north' format
    path - path to the shapefile, which should be either an esri .shp file or
        a netcdf mask file.
    shape - the shape identifier (gShapeID) within the esri shapefile. Ignored
        if this is a netcdf mask file
    '''

    if shape is None:
        return intersects_mask(bbox, path)
    else:
        return intersects_esri(bbox, path, shape)


def intersects_mask(bbox, path):
    '''
    Returns True if the input shape intersects bbox and False otherwise.

    bbox - bounding box string in 'west,south,east,north' format
    path - path to the shapefile, a netcdf mask file.
    '''

    parsed_box = BBox(bbox)
    # divide the bounding box at the 180 meridian to make the logic easier
    bboxes = parsed_box.divide_at_180()

    with Dataset(path, 'r') as nc:
        # get out the latitudes and longitudes
        lons = nc.variables['lon'][:]
        lats = nc.variables['lat'][:]
        for b in bboxes:
            # see which latitudes and longitudes fix in our bounding box
            lons_in_bbox = np.logical_and(
                lons >= b.west,
                lons <= b.east)
            lats_in_bbox = np.logical_and(
                lats >= b.south,
                lats <= b.north)

            if (not np.any(lons_in_bbox)) or (not np.any(lats_in_bbox)):
                return False



            # get out just that data
            data = nc.variables['shape_mask'][lats_in_bbox, lons_in_bbox]

            # see if any mask values in the subsetted data are non-zero.
            if np.count_nonzero(data) > 0:
                return True

    return False


def intersects_esri(bbox, path, shape):
    '''
    Returns True if the input shape intersects bbox and False otherwise.

    bbox - bounding box string in 'west,south,east,north' format
    path - path to the esri shapefile
    shape - the shape identifier (gShapeID) within the esri shapefile. Ignored
        if this is a netcdf mask file


    Derived from http://gis.stackexchange.com/questions/126467/determine-if-shapefile-and-raster-overlap-in-python
    '''
    # open the shapefile
    vector = ogr.Open(path)
    if vector is None:
        raise IntersectError("Unable to open shapefile %s" % path)

    # there's only one layer, so get it out
    layer = vector.GetLayer(0)
    # find the correct feature
    feature = None
    i = 0
    while feature is None and i < layer.GetFeatureCount():
        if layer.GetFeature(i).GetFieldAsString('gShapeID') == shape:
            feature = layer.GetFeature(i)

        i += 1

    if feature is None:
        vector.Destroy()
        raise IntersectError("Unable to find id %s in %s." % (shape, path))

    # parse the bounding box
    parsed_box = BBox(bbox)
    ret = False
    bboxes = parsed_box.divide_at_180()
    for b in bboxes:
        # describe the bounding box geometry
        ring = ogr.Geometry(ogr.wkbLinearRing)
        ring.AddPoint(b.west, b.south)
        ring.AddPoint(b.east, b.south)
        ring.AddPoint(b.east, b.north)
        ring.AddPoint(b.west, b.north)
        ring.AddPoint(b.west, b.south)
        bbox_geometry = ogr.Geometry(ogr.wkbPolygon)
        bbox_geometry.AddGeometry(ring)
    
        # calculate the intersection
        if bbox_geometry.Intersect(feature.GetGeometryRef()):
            ret = True

    # release memory for this shapefile
    vector.Destroy()
    return ret
