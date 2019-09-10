#!/bin/env python
"""
Reads the available provisioned shapefiles and their info files, and returns
them to the client via JSON.
"""
__author__ = 'Daniel da Silva <daniel.e.dasilva@nasa.gov>'

import simplejson as json

import cgi_utils; cgi_utils.patch_path()
from agiovanni.shapefileUtilities import ShapefileUtility


def main():
    shp_util = ShapefileUtility()
    prefixes = shp_util.findProvisionedShapefiles()
    prefixes = sorted(prefixes)

    json_out = {}    
    json_out['available'] = prefixes
    json_out['info'] = {}

    for prefix in prefixes:    
        json_out['info'][prefix] = shp_util.readProvisionedInfo(prefix)

    print "Content-Type: application/json"
    print
    print json.dumps(json_out)
    

if __name__ == '__main__':
    main()
