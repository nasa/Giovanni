#!/bin/env python

from distutils.core import setup

setup(name='Giovanni',
      version='4',
      description='Interactive Visualization and Analysis',
      author='GES DISC, Code 610.2',
      url='http://disc.gsfc.nasa.gov/giovanni',
      packages=['agiovanni'],
      scripts=[
          'scripts/map_plot/python_map_visualizer.py',
          'scripts/area_stats/calc_area_statistics.py',
          'scripts/make/format_region.py',
          'scripts/net_cdf_serializer/net_cdf_serializer.py',
          'scripts/ints_serializer/serialize_ints.py',
          'scripts/smart_diff/diff_nc.py',
          'scripts/smart_diff/sort_nc.py',
          'scripts/remove_nans/remove_nans.py'
      ], requires=['numpy', 'netCDF4']
      )
