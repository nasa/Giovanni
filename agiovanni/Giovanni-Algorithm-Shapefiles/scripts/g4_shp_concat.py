#!/bin/env python
"""Concatenates multiple shapefiles.

This was created for the US State Department countries shapefiles,
which are seperated into one shapefile for each continent.
"""

__author__ = 'Daniel da Silva <Daniel.e.daSilva@nasa.gov>'

import itertools
import os
import sys

import shapefile


def main(argv):
    # Parse command-line arguments
    # ------------------------------------------------------------------
    if len(argv) < 3 or '--help' in argv:
        print 'Usage: %s OUT_SHP IN_SHP1 IN_SHP2 [...]' \
            % os.path.basename(argv[0])
        print
        print sys.modules[__name__].__doc__
        sys.exit(1)
    else:
        out_shp = argv[1]
        in_shps = argv[2:]

    # Read
    # ------------------------------------------------------------------
    read_fields = []
    read_shapes = []
    read_records = []
    n = len(in_shps)

    for i, in_shp in enumerate(in_shps):
        percent = int( 100 * float(i) / float(n) )
        sys.stdout.write('\rReading %d/%d (%2d%%)' % (i + 1, n, percent))
        sys.stdout.flush()
        
        in_shp_reader = shapefile.Reader(in_shp)
        read_fields.append(in_shp_reader.fields[1:]) # drop 'DeletionFlag'
        read_shapes.append(in_shp_reader.shapes())
        read_records.append(in_shp_reader.records())
        
    sys.stdout.write('\rReading %d/%d (100%%)' % (n, n))
    sys.stdout.flush()
    print

    # Rewrite records to same order
    # We assume each shapefile contains the same fields, however they
    # may be in a different order.
    # ------------------------------------------------------------------
    print 'Reordering fields...'
    write_fields = read_fields[0]
    write_shapes = list(itertools.chain(*read_shapes))        # flatten
    write_records = []

    # Construct map from field names to correct record indexes
    defacto_idxs = {}                              # maps name => index

    for i, field in enumerate(write_fields):
        field_name = field[0]
        defacto_idxs[field_name.upper()] = i

    assert sorted(defacto_idxs.values()) == range(len(write_fields))

    # Build list of reordered records to write
    for fields, records in itertools.izip(read_fields, read_records):
        # Construct map of old record indexes to new record indexes
        idx_remap = {}

        for i, field in enumerate(fields):
            field_name = field[0]
            idx_remap[i] = defacto_idxs[field_name.upper()]

        assert sorted(idx_remap.keys()) == range(len(records[0]))

        # Build list of reordered records
        reordered_records = []

        for record in records:
            reordered_record = [None] * len(record)
            for i, value in enumerate(record):
                reordered_record[idx_remap[i]] = value

            assert None not in reordered_record
            reordered_records.append(reordered_record)
        
        write_records.extend(reordered_records)

    # Write to memory
    # ------------------------------------------------------------------
    out_shp_writer = shapefile.Writer()

    for field in write_fields:
        out_shp_writer.field(*field)

    assert len(write_shapes) == len(write_records)
    n = len(write_shapes)
        
    for i, (shape, record) in enumerate(itertools.izip(write_shapes, write_records)):
        percent = int( 100 * float(i) / float(n) )
        sys.stdout.write('\rWriting to memory %d/%d (%2d%%)' % (i + 1, n, percent))
        sys.stdout.flush()

        parts = list(shape.parts)
        parts.append(len(shape.points))
        polys = [shape.points[parts[i]:parts[i+1]]
                 for i in xrange(len(parts) - 1)
                 if parts[i] < parts[i+1]]

        out_shp_writer.poly(shapeType=shape.shapeType, parts=polys)
        out_shp_writer.record(*record)

    sys.stdout.write('\rWriting to memory %d/%d (100%%)' % (n, n))
    sys.stdout.flush()
    print

    # Write to disk
    # -------------------------------------------
    print 'Writing to disk...'

    out_shp_writer.save(out_shp)

if __name__ == '__main__':
    main(sys.argv)
