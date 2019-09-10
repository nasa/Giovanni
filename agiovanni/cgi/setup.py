#!/bin/env python

from distutils.core import setup

setup(name='Giovanni',
      version='4',
      description='Interactive Visualization and Analysis',
      author='GES DISC, Code 610.2',
      url='http://disc.gsfc.nasa.gov/giovanni',
      scripts=[
          'cgi_utils.py',
          'getGeoJSON.py',
          'getProvisionedShapefiles.py',
      ],
      )
