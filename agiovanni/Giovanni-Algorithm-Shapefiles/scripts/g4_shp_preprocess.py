#!/bin/env python
"""
Pre-processes shape files for use in AG. The main act is generating a JSON file that relays the shapefile's information + AG metadata in a more accessible format.

Example:
  g4_shp_preprocess.py state_dept_countries \\
     --title='Countries' --label=1 --sourceName='US State Department' \\
     --sourceURL='https://hiu.state.gov/data/data.aspx'
Example 
  g4_shp_preprocess.py gpmLandSeaMask \\
     --title='gpm mask' --label=1 --sourceName='GES_DISC' \\
     --sourceURL='http://dev.gesdisc.eosdis.nasa.gov/~rstrub/giovanni/shapes/'
"""

__author__ = ('Daniel da Silva <daniel.e.dasilva@nasa.gov>',
              'Richard Strub <richard.f.strub@nasa.gov>')

import optparse
import os
import sys
import glob

# We have to manually add AG installation python lib location to the path 
# because we are not necessarily running in an environment where it is set.
cur_dir = os.path.dirname(os.path.abspath(__file__))
path = os.path.join(cur_dir, '..', 'lib/python%s/site-packages' % sys.version[:3])
sys.path.append(path)

from agiovanni import shapefileUtilities
from agiovanni import ncmaskfileUtilities

def main(argv):    
    # Parse command line arguments
    parser = optparse.OptionParser()

    parser.add_option('-T', '--title', dest='title', help='Title of shapefile')
    parser.add_option('-L', '--label',type=int, dest='label_idx', help='Index of label field')
    parser.add_option('--sourceName', dest='source_name', help='Name of source of shapefile')
    parser.add_option('--sourceURL', dest='source_url', help='URL to web page for source')

    try:
        options, args = parser.parse_args(argv[1:])
    except SystemExit:
        print sys.modules[__name__].__doc__
	print "USAGE EXAMPLES: (cd to shapefile dir)"
	print
	"""
  g4_shp_preprocess.py state_dept_countries \\
     --title='Countries' --label=1 --sourceName='US State Department' \\
     --sourceURL='https://hiu.state.gov/data/data.aspx'
  g4_shp_preprocess.py gpmLandSeaMask \\
     --title='gpm mask' --label=1 --sourceName='GES_DISC' \\
     --sourceURL='http://dev.gesdisc.eosdis.nasa.gov/~rstrub/giovanni/shapes/'
	"""
        sys.exit(1)

    # Validate
    if len(args) != 1:
        print >>sys.stderr, 'Positional argument missing'
        parser.print_help()
        print >>sys.stderr, sys.modules[__name__].__doc__
        sys.exit(1)

    required_args = [
        ('--title', options.title),
    ]

    for arg_switch, arg_value in required_args:
        if arg_value is None:
            print >>sys.stderr,'%s is required' % arg_switch
            parser.print_help()
            print >>sys.stderr, sys.modules[__name__].__doc__
            sys.exit(1)
        
    
    # Main execution
    shp = shapefileUtilities.ShapefileUtility()

    try:
    	load_errors = shp.loadShapefile(args[0])
	if load_errors:
            print 'Load Error:', load_errors
            sys.exit(1)

    except: # maybe netcdf mask, not ESRI shapefile mask:
            shp = ncmaskfileUtilities.NetCDFMaskFileUtility(sys.argv[1])
            load_errors = shp.loadNetCDFFile()
            if load_errors:
                print 'Load Error:', load_errors
                sys.exit(1)

    write_errors = shp.writeInfo(args[0] + '.json', 
                                 title=options.title, 
                                 label_idx=options.label_idx, 
                                 source_name=options.source_name, 
                                 source_url=options.source_url) 

    if write_errors:
        print 'Write Error:', write_errors
        sys.exit(1)

    print
    print 'Done'


if __name__ == '__main__':
    main(sys.argv)

