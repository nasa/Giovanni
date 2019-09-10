#!/bin/env python
"""Remove unrecognized countries from the countries shapefile info file.

Given the countries shapefile info file (see g4_shp_preprocess.py to
generate), this script removes shapes that contain 2 digit ISO codes not
found in the US State Dept World Polygons file.

Run with --help for usage.
"""
__author__ = 'Daniel da Silva <Daniel.daSilva@nasa.gov>'

import optparse
import sys

import simplejson as json


# Each shape has an array of values. There are the indeces in the countries
# shapefile and world polygons shapefile of the 2 digit ISO country codes,
# eg FR for France.
COUNTRIES_ISO_IDX = 3
STATE_DEPT_ISO_IDX = 3


def read_iso_codes(prefix, iso_idx):
    """Read the iso codes in an shapefile info file"""
    info_fname = prefix + '.json'
        
    try:
        info_fh = open(info_fname)
    except IOError:
        print 'Could not open', info_fname
        print 'Perhaps the shapefile', prefix, 'was not run through',
        print 'g4_shp_preprocess.py?'
        exit(1)
        
    info = json.load(info_fh)
    info_fh.close()

    iso_codes = set()

    for shape in info['shapes'].values():
        iso_codes.add(shape['values'][iso_idx].upper())
        
    return iso_codes


def remove_filtered(prefix, filter_codes):
    """Removes filtered shapes from info file"""
    info_fname = prefix + '.json'

    info_fh = open(info_fname)
    info = json.load(info_fh)
    info_fh.close()

    info['filter'] = []
    
    for shape_id, shape in info['shapes'].items():
        iso_code = shape['values'][COUNTRIES_ISO_IDX]
        if iso_code in filter_codes:
            del info['shapes'][shape_id]
            
    info_fh = open(info_fname, 'w')
    json.dump(info, info_fh)
    info_fh.close()


def main(argv):
    if len(argv) < 3 or '--help' in argv:
        print 'Usage:', argv[0], ('COUNTRIES_SHAPEFILE_PREFIX '
                                  'STATE_DEPT_SHAPEFILE_PREFIX_1 '
                                  '[STATE_DEPT_SHAPEFILE_PREFIX_2 [...]]')
        print
        print 'Example:', argv[0], ('countryAreas Africa Asia_Russia '
                                    'Europe_SWAsia North_America '
                                    'Oceania_to_Malay_Antarc_ SouthAmerica')
        exit(1)

    allowed_codes = set()
    for prefix in sys.argv[2:]:
        allowed_codes.update(read_iso_codes(prefix, STATE_DEPT_ISO_IDX))

    existing_codes = read_iso_codes(sys.argv[1], COUNTRIES_ISO_IDX)    

    filter_codes = existing_codes - allowed_codes

    remove_filtered(sys.argv[1], filter_codes)

    print 'Done (%d filtered)' % len(filter_codes)


if __name__ == '__main__':
    main(sys.argv)

        
    
        
    



