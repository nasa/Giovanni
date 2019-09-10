'''
Tests the format_bbox.py script
'''
__author__ = "Christine Smit <christine.e.smit@nasa.gov>"

import unittest
import StringIO

import format_region as fb


class IntegrationTest(unittest.TestCase):

    def test_main(self):
        output_stream = StringIO.StringIO()
        argv = [
            "-N=2",
            "-S=tl_2014_us_state/shp_13",
            "-C=3",
            "-b=-180.0,-90.0,180.0,90.0"]
        fb.main(argv, output_stream)
        self.assertEquals(
            output_stream.getvalue(),
            "180.00W90.00S180.00E90.00NsUZ", "shape and bounding box")
        output_stream.close()

        output_stream = StringIO.StringIO()
        argv = [
            "-N=2",
            "-S=",
            "-C=3",
            "-b="]
        fb.main(argv, output_stream)
        self.assertEquals(
            output_stream.getvalue(),
            "", "no shape or bbox")
        output_stream.close()        
        
        output_stream = StringIO.StringIO()
        argv = [
            "-N=2",
            "-S=tl_2014_us_state/shp_13",
            "-C=3",
            "-b="]
        fb.main(argv, output_stream)
        self.assertEquals(
            output_stream.getvalue(),
            "sUZ", "just shape")
        output_stream.close()

        output_stream = StringIO.StringIO()
        argv = [
            "-S=tl_2014_us_state/shp_13",
            "-b=-180.0,-90.0,180.0,90.0"]
        fb.main(argv, output_stream)
        self.assertEquals(
            output_stream.getvalue(),
            "180.0000W90.0000S180.0000E90.0000NsUZ", "use defaults")
        output_stream.close()

        output_stream = StringIO.StringIO()
        argv = ["-b=-180.0,-90.0,180.0,90.0"]
        fb.main(argv, output_stream)
        self.assertEquals(
            output_stream.getvalue(),
            "180.0000W90.0000S180.0000E90.0000N", "no shape")
        output_stream.close()

        output_stream = StringIO.StringIO()
        argv = [
            "-S=watersheds/shp_3",
            "-b=-180.0,-90.0,180.0,90.0"]
        fb.main(argv, output_stream)
        self.assertEquals(
            output_stream.getvalue(),
            "180.0000W90.0000S180.0000E90.0000NeNN", "different shape")
        output_stream.close()

    def test_format_bbox(self):
        self.assertEqual(
            fb.format_bbox(
                "0, 0, 0, 0",
                4),
            "0.0000E0.0000N0.0000E0.0000N",
            "4 after the decimal point")

        self.assertEqual(
            fb.format_bbox(
                "0, 1, 2, 3",
                2),
            "0.00E1.00N2.00E3.00N",
            "2 after the decimal point")

        self.assertEqual(
            fb.format_bbox(
                "-10.0, -3, -1, -2.7890982734",
                4),
            "10.0000W3.0000S1.0000W2.7891S",
            "4 after the decimal point")

        self.assertEqual(
            fb.format_bbox(None),
            "",
            "Can accept no bounding box")

    def test_calc_checksum(self):
        self.assertEqual(
            fb._calc_checksum("523452447",
                              ['0',
                               '1',
                               '2',
                               '3',
                               '4',
                               '5',
                               '6',
                               '7',
                               '8',
                               '9'],
                              3),
            '422', 'Correct 3-digit, based 10 calculation')
        self.assertEqual(
            fb._calc_checksum("24999837",
                              ['0',
                               '1',
                               '2',
                               '3',
                               '4',
                               '5',
                               '6',
                               '7',
                               '8',
                               '9'],
                              3),
            '860', 'Correct 3-digit, based 10 calculation')

        self.assertEqual(
            fb._calc_checksum("CBBC", ['A', 'B', 'C'], 2),
            'BA', 'Correct base 3 calculation')


if __name__ == "__main__":
    unittest.main()
