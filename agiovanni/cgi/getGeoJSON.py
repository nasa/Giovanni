#!/bin/env python
"""
Cgi for delivering the .geojson file associated with a shape.
Takes one query parameter: shape=name (without any of the suffixes).
parameter name is: <shapefile>_shp_<#>

E.g. -

https://giovanni.gsfc.nasa.gov/giovanni/daac-bin/getGeoJSON.py?shape=state_dept_countries_shp_45

"""
__author__ = 'Richard Strub <richard.f.strub@nasa.gov>', \
             'Christine Smit <christine.e.smit@nasa.gov>'

import sys
import os

import cgi_utils
cgi_utils.patch_path()


class CgiError(Exception):
    """
    Class for errors associated with calculating the intersection.
    """
    pass


def _get_shape(query, qstring):
    """
    Get the shape parameter out of the query string.
    """

    shape = None
    # make sure it has the shape parameter and only the shape parameter
    for param in query:

        if param == "shape":
            if len(query[param]) != 1:
                raise CgiError(
                    "Expected only a single shape in query string: %s" %
                    qstring)

            shape = query[param][0]
            shape = shape.replace("/shp","_shp");
        else:
            raise CgiError(
                "Unrecognized query string key. Expected 'shape' . query string: %s" % qstring)

    if shape is None:
        raise CgiError("Did not get shape in query: %s" % qstring)

    return shape


def main(config_env=None, qstring=None, stdout=sys.stdout):
    """
    Calculates intersection.

    config_env - should behave like agiovanni.cfg.ConfigEnvironment. Optional.
        Used for testing.
    qstring - query string for request. Used for testing. Generally derived
        from QUERY_STRING environment variable
    stdout - where to write output
    """

    # configure environment, if necessary
    if config_env is None:
        cgi_utils.patch_path()
        from agiovanni.cfg import ConfigEnvironment
        config_env = ConfigEnvironment()

    # get the cgi query string
    if qstring is None:
        qstring = os.environ['QUERY_STRING']

    # parse the query string and check the parameter values
    query = cgi_utils.get_query_params(qstring)

    # get the shape and parameter out of the query
    shape = _get_shape(query, qstring)

    # get the location of the shapefiles
    shape_dir = config_env.getGeoJSONProvisionedDir()

    path = os.path.join(shape_dir, "%s.geojson" % shape)

    geojson_data = '{}'

    if os.path.exists(path):
        try:
            geojsonFile = open(path, "r")
        except IOError:
            raise CgiError("Unable to open %s for read" % path)
        with geojsonFile:
            geojson_data = geojsonFile.read()

    # write out the http response
    stdout.write("Content-Type: text/json\n\n%s\n" % geojson_data)


if __name__ == '__main__':
    main()
