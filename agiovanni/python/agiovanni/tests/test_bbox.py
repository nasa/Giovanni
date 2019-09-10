'''
Tests agiovanni.bbox.
'''
__author__ = 'Christine Smit <christine.e.smit@nasa.gov>'

import unittest

import agiovanni.bbox as bb


class Test(unittest.TestCase):

    def testParseBbox(self):
        bbox = bb.BBox("-180,-90,180,90")
        self.assertEqual(bbox.west, -180, "west")
        self.assertEqual(bbox.south, -90, "south")
        self.assertEqual(bbox.east, 180, "east")
        self.assertEqual(bbox.north, 90, "north")

        self.assertEqual(
            str(bbox),
            "-180.000000,-90.000000,180.000000,90.000000",
            "string: %s" %
            str(bbox))

    def testAcross180(self):
        self.assertTrue(
            bb.BBox(
                west=170,
                east=-170,
                south=0,
                north=1).goes_over_180(),
            'Goes over 180')
        self.assertFalse(
            bb.BBox(
                west=-180,
                east=-170,
                south=0,
                north=1).goes_over_180(),
            'Not over 180')

    def testEq(self):
        self.assertTrue(
            bb.BBox("-180,-90,180,90") == bb.BBox("-180.0,-90.0,180.0,90.0"))

        self.assertTrue(
            bb.BBox("-180,-90,180,90") != bb.BBox("-176.0,-90.0,180.0,90.0"))

    def testDivide(self):
        out = bb.BBox("165,-4,0,-3").divide_at_180()
        self.assertSequenceEqual(
            out, [
                bb.BBox("165,-4,180,-3"), bb.BBox("-180,-4,0,-3")], "Correct division")

        out = bb.BBox("-170,10,-145,20").divide_at_180()
        self.assertSequenceEqual(
            out, [bb.BBox("-170,10,-145,20")], "No division needed")

if __name__ == "__main__":
    unittest.main()
