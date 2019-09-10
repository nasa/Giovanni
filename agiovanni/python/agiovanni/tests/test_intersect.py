'''
Tests agiovanni.intersect code.
'''
__author__ = 'Christine Smit <christine.e.smit@nasa.gov>'

import unittest
import os

import agiovanni.intersect as intersect


class Test(unittest.TestCase):
    """Tests that the intersection code."""

    def setUp(self):
        test_dir = os.path.dirname(__file__)
        self.test_file_dir = os.path.join(test_dir, 'test_intersect')

    def testEsriShapefile(self):
        
        us_states = os.path.join(self.test_file_dir, 'tl_2014_us_state.shp')
        countries =  os.path.join(self.test_file_dir, 'state_dept_countries.shp')

        # NOTE: Maryland is shp_4
        self.assertTrue(
            intersect.intersects("-180,-90,180,90", us_states, 'shp_4'),
            "Maryland shape intersects with the entire globe")

        self.assertTrue(
            intersect.intersects(
                "-76.5527, 39.0271, -75.1025, 40.2356",
                us_states,
                'shp_4'),
            "Maryland shape intersects with smaller bounding box")

        self.assertFalse(
             intersect.intersects(
                "-129.375, 24.7266, -68.9062, 57.0703",
                 countries,
                 'shp_162'),
              "Nigeria shape does not intersect with bounding box over United States")

        self.assertFalse(
            intersect.intersects(
                "-78.9258, 38.4558, -77.915, 39.2029",
                us_states,
                'shp_4'),
            "Maryland shape does not intersect with bounding box in Virginia")

        self.assertFalse(
            intersect.intersects(
                "-77, 39, -77, 39",
                us_states,
                'shp_4'),
            "Points don't intersect with shapes.")

        # NOTE: Alaska is shp_40
        self.assertTrue(
            intersect.intersects(
                "172.8369, 50.5005, -179.6045, 53.8403",
                us_states,
                'shp_40'),
            "Alaska intersects with bounding box over 180 meridian")

        self.assertTrue(
            intersect.intersects(
                "164.6631, 50.5518, -167.0361, 56.792",
                us_states,
                'shp_40'),
            "Alaska intersects with bounding box over 180 meridian")

        self.assertFalse(
            intersect.intersects(
                "168.6182, 11.3086, -168.8818, 33.8086",
                us_states,
                'shp_40'),
            "Alaska does not intersect with this bounding box over 180 meridian")


        self.assertFalse(
            intersect.intersects(
                "176.5283, 53.9282, -175.8691, 57.2681",
                us_states,
                'shp_40'),
            "Alaska does not intersect with this bounding box over 180 meridian")




    def testMaskShape(self):
        gpm = os.path.join(self.test_file_dir, "gpmLandSeaMask.nc")
        self.assertTrue(
            intersect.intersects(
                "-180,-90,180,90",
                gpm),
            "GPM land sea mask has positive values somewhere on the planet")

        self.assertTrue(
            intersect.intersects(
                "-54.1406, -28.7109, -30.9375, -4.8047",
                gpm),
            "GPM land sea mask has positive values off Brazil coast")
        self.assertFalse(
            intersect.intersects(
                "18.9404, -33.4351, 23.2031, -29.7876",
                gpm),
            "GPM land sea mask has no positive values in the middle of South Africa")
        self.assertFalse(
            intersect.intersects(
                "179.2969, 66.98, -179.2969, 68.1665",
                gpm),
            "GPM land sea mask has no positive values in Russia over 180 meridian")
        self.assertTrue(
            intersect.intersects(
                "171.5625, 26.0742, -173.6719, 35.5664",
                gpm),
            "GPM land sea mask is all zero over 180 meridian in the Pacific")
        
        self.assertFalse(
            intersect.intersects(
                "0.0,0.0,0.0,0.0",
                gpm),
            "Points don't intersect")       

if __name__ == "__main__":
    unittest.main()
