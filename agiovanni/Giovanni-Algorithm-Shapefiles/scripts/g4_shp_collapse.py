#!/bin/env python
"""Collapse single-polygon shapes into multi-polygon shapes by grouping on a field.

Some shapefiles are organized such that every individual polygon is a seperate
shape. For example, every island of hawaii is a different shape. For ingestion
to G4, we desire the entire state of Hawaii to be one shape.
"""

__author__ = 'Daniel da Silva <Daniel.e.daSilva@nasa.gov>'

import collections
import itertools
import os
import sys

import shapefile


def main(argv):
    # Parse command-line arguments
    # -------------------------------------------
    if len(argv) == 4:
        group_by, in_shp, out_shp = argv[1:]
    else:
        print 'Usage: %s GROUP_BY IN_SHP OUT_SHP' % os.path.basename(argv[0])
        print
        print sys.modules[__name__].__doc__
        sys.exit(1)

    # Look for index of grouping field 
    # -------------------------------------------
    in_shp_reader = shapefile.Reader(in_shp)
    field_idx = None

    for i, field in enumerate(in_shp_reader.fields):
        if field[0] == group_by:
            field_idx = i
            break
    
    if field_idx is None:
        print 'Error: field', group_by, 'not found in file'
        sys.exit(1)
    
    # Read
    # -------------------------------------------
    grouped = {}    
    n = in_shp_reader.numRecords

    for i, (shape, record) in enumerate(itertools.izip(in_shp_reader.iterShapes(),
                                                       in_shp_reader.iterRecords())):
        percent = int( 100 * float(i) / float(n - 1) )
        sys.stdout.write('\rReading %d/%d (%2d%%)' % (i + 1, n, percent))
        sys.stdout.flush()

        if shape.shapeType != 5:
            # skip non-polygon shapes
            continue

        key = record[field_idx]
        parts = list(shape.parts)
        parts.append(len(shape.points))
        points = shape.points
        polys = [shape.points[parts[i]:parts[i+1]]
                 for i in xrange(len(parts) - 1)
                 if parts[i] < parts[i+1]]

        if key in grouped:
            grouped[key]['polys'].extend(polys)
        else:
            grouped[key] = {
                'shapeType': shape.shapeType,
                'polys': polys,
                'record': record,
            }

    print

    # Write to memory
    # -------------------------------------------
    out_shp_writer = shapefile.Writer()

    for field in in_shp_reader.fields:
        out_shp_writer.field(*field)

    items = grouped.items()
    items.sort(key=lambda p: p[0])
    dicts = [p[1] for p in items]
    n = len(dicts)

    for i, dict_ in enumerate(dicts):
        percent = int( 100 * float(i) / float(n - 1) )
        sys.stdout.write('\rWriting to memory %d/%d (%2d%%)' % (i + 1, n, percent))
        sys.stdout.flush()
        
        out_shp_writer.poly(shapeType=dict_['shapeType'], parts=dict_['polys'])
        out_shp_writer.record(*dict_['record'])

    print

    # Write to disk
    # -------------------------------------------
    print 'Writing to disk...'

    out_shp_writer.save(out_shp)
    


if __name__ == '__main__':
    main(sys.argv)
