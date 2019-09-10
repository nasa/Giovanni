"""Geographic classes and functions."""


class Bounds(object):
    """Immutable class for holding geographic bounds."""
    
    def __init__(self, west, south, east, north):
        self.west = west
        self.south = south
        self.east = east
        self.north = north
        self.immutable = True
        
    def __setattr__(self, name, value):
        if getattr(self, 'immutable', False):
            raise AttributeError("Class is immutable");
        object.__setattr__(self, name, value)

    def extend(self, delta_lon, delta_lat):
        """Extend the bounds by a delta in each direction."""
        return Bounds(
            max(-180, self.west  - delta_lon),
            max( -90, self.south - delta_lat),
            min( 180, self.east  + delta_lon),
            min(  90, self.north + delta_lat),
        )

class Resolution(object):
    """Immutable class for holding geographic resolution."""
    
    def __init__(self, lon_res, lat_res):
        self.lon = lon_res
        self.lat = lat_res
        self.immutable = True

    def __setattr__(self, name, value):
        if getattr(self, 'immutable', False):
            raise AttributeError("Class is immutable");
        object.__setattr__(self, name, value)

    def __repr__(self):
        return 'Resolution' + str(repr((self.lon, self.lat)))

    def scale(self, factor):
        return Resolution(self.lon * factor, self.lat * factor)
            
