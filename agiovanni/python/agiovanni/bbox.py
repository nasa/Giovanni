'''
Library for dealing with bounding boxes.

Created on Apr 26, 2016
'''
__author__ = 'Christine Smit <christine.e.smit@nasa.gov>'

class BBoxError(Exception):
    '''
    Class for errors associated with bounding boxes.
    '''
    pass


class BBox(object):
    '''
    This class has bounding box utility functions
    '''

    def __init__(
            self, bbox=None, west=None, south=None, east=None, north=None):
        '''
        Constructor. Either bbox must be specified or west, south, east, and
        north must be specified.

        bbox - bounding box in 'west,south,east,north' format
        west - west edge of bounding box
        south - south edge of bounding box
        east - east edge of bounding box
        north - north edge of bounding box.
        '''
        if bbox is not None:
            values = [float(v) for v in bbox.split(",")]
            if len(values) != 4:
                raise BBoxError("Unable to parse bounding box %s" % bbox)
            self.west = values[0]
            self.south = values[1]
            self.east = values[2]
            self.north = values[3]
        elif west is not None and south is not None and east is not None and north is not None:
            self.west = west
            self.south = south
            self.east = east
            self.north = north

        if self.north > 90 or self.north < -90:
            raise BBoxError("North outside of [-90,90] range: %f" % self.north)
        if self.south > 90 or self.south < -90:
            raise BBoxError("South outside of [-90,90] range: %f" % self.south)
        if self.west > 180 or self.west < -180:
            raise BBoxError("West outside of [-180,180] range: %f" % self.west)
        if self.east > 180 or self.east < -180:
            raise BBoxError("East outside of [-180,180] range: %f" % self.east)

    def __str__(self):
        '''
        Returns a string representation of the bounding box in
        'west,south,east,north' format.
        '''
        return "%f,%f,%f,%f" % (self.west, self.south, self.east, self.north)

    def __eq__(self, other):
        '''
            Tests to make sure all 4 coordinates are the same/
            '''
        return self.west == other.west \
            and self.east == other.east \
            and self.south == other.south \
            and self.north == other.north

    def goes_over_180(self):
        '''
        Returns True if this bounding box crosses the 180 meridian and False
        otherwise.
        '''

        if self.west > self.east:
            return True
        else:
            return False

    def divide_at_180(self):
        '''
        Splits the bounding box along the 180 meridian and returns two bounding
        boxes. If the current bounding box doesn't cross the 180 meridian,
        the current bounding box is returned.
        '''

        if not self.goes_over_180():
            return [self]

        return[BBox(north=self.north, south=self.south, west=self.west, east=180.0),
               BBox(north=self.north, south=self.south, west=-180.0, east=self.east)]
