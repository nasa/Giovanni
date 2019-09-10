"""Tests for the agiovanni.geo module."""

import unittest

import agiovanni.geo

class TestBounds(unittest.TestCase):
    """Tests that the Bounds class."""
    
    def test_immutability(self):
        bounds = agiovanni.geo.Bounds(-180, -90, 180, 90)
        
        def set_west():
            bounds.west = -179
        def set_south():
            bounds.south = -89
        def set_east():
            bounds.east = -89
        def set_north():
            bounds.north = 89

        self.assertRaises(AttributeError, set_west)
        self.assertRaises(AttributeError, set_south)
        self.assertRaises(AttributeError, set_east)
        self.assertRaises(AttributeError, set_north)

    def test_extend_out_of_bounds(self):
        bounds = agiovanni.geo.Bounds(-60, -45, 60, 45)
        bounds = bounds.extend(1000, 1000)
        
        self.assertEqual(bounds.west, -180)
        self.assertEqual(bounds.south, -90)
        self.assertEqual(bounds.east, 180)
        self.assertEqual(bounds.north, 90)
        
    def test_extend_bounds_inwards(self):
        bounds = agiovanni.geo.Bounds(-60, -45, 60, 45)
        bounds = bounds.extend(-10, -5)

        self.assertEqual(bounds.west, -50)
        self.assertEqual(bounds.south, -40)
        self.assertEqual(bounds.east, 50)
        self.assertEqual(bounds.north, 40)


class TestResolution(unittest.TestCase):
    """Tests the resolution class."""
    
    def test_immutability(self):
        res = agiovanni.geo.Resolution(0.5, 0.5)
        
        def set_lon():
            res.lon = 1.0
        def set_lat():
            res.lat = 1.0

        self.assertRaises(AttributeError, set_lon)
        self.assertRaises(AttributeError, set_lat)
        
    def test_scale_to_higher_res(self):
        res = agiovanni.geo.Resolution(1.0, 1.0)
        scaled_res = res.scale(0.5)
        self.assertEqual(scaled_res.lon, 0.5)
        self.assertEqual(scaled_res.lat, 0.5)

        res = agiovanni.geo.Resolution(1.0, 2.0)
        scaled_res = res.scale(0.5)
        self.assertEqual(scaled_res.lon, 0.5)
        self.assertEqual(scaled_res.lat, 1.0)

    def test_scale_to_lower_res(self):
        res = agiovanni.geo.Resolution(1.0, 1.0)
        scaled_res = res.scale(2)
        self.assertEqual(scaled_res.lon, 2.0)
        self.assertEqual(scaled_res.lat, 2.0)

        res = agiovanni.geo.Resolution(1.0, 2.0)
        scaled_res = res.scale(2)
        self.assertEqual(scaled_res.lon, 2.0)
        self.assertEqual(scaled_res.lat, 4.0)

if __name__ == '__main__':
    unittest.main()        
