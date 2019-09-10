#!/bin/env python
"""
Dumps output of a provisioned shapefile preprocessed file for
inspection. Use -X to list info on each shape.

Example:
$ g4_shp_dump.py us_states
"""
__author__ = 'Daniel da Silva <daniel.e.dasilva@nasa.gov>'

import pprint
import sys

import simplejson as json


def dump(info_path, extended=False):
    """Print a dump of the info file"""    
    info = json.load(open(info_path + '.json'))
    print 'prefix:', info['parentDir']
    print 'title:', info['title']
    print 'labels:', '%d=%s'%(info['bestAttr'][1], info['fields'][info['bestAttr'][1]][0])
    print 'fields:', ', '.join('%d=%s'%(i,t[0]) for i,t in enumerate(info['fields']))
    print 'shapes:', len(info['shapes'])
    if extended:
        pprint.pprint(info['shapes'])
            
    print



def main(argv):
    """Main routine"""

    if '-X' in argv:
        extended = True
        argv = argv[:]    
        argv.remove('-X')
    else:
        extended = False

    if len(argv) == 1:
        print sys.modules[__name__].__doc__
        return

    for info_path in argv[1:]:
        dump(info_path, extended)
    

if __name__ == '__main__':
    main(sys.argv)
