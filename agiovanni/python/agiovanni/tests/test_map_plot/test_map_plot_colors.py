"""
Tests for the agiovanni.map_plot module.
"""

__author__ = "Christine Smit <christine.e.smit@nasa.gov>"

import unittest
import tempfile
import shutil
import os
from lxml import etree
from PIL import Image

import agiovanni.map_plot as mp


class IntegrationTest(unittest.TestCase):

    def setUp(self):
        self.dir = tempfile.mkdtemp()
        self.curr_dir = os.path.abspath(os.path.dirname(__file__))

    def tearDown(self):
        shutil.rmtree(self.dir)

    def testColorsAreValid(self):
        '''Test to make sure that plotting creates an image with the correct
        colors.
        '''

        # get the colors out of the SLD
        sld = os.path.join(
            self.curr_dir,
            'AIRX3STM_006_Temperature_A_19582_1469474352divergent_burd_11_sld.xml')
        (colors, fallback_color) = readSld(sld)

        all_colors = list(colors)
        all_colors.append(fallback_color)

        # visualize the data
        nc = os.path.join(
            self.curr_dir,
            'g4.timeAvgMap.AIRX3STM_006_Temperature_A.100hPa.20150801-20150831.88W_26N_71W_45N.nc')
        variable_name = 'AIRX3STM_006_Temperature_A'

        v = mp.Visualize(
            nc,
            sld,
            variable_name=variable_name,
            inflation_factor=1)
        output_file = os.path.join(self.dir, "out.png")
        v.plot(output_file)

        # read the output image
        im = Image.open(output_file)
        im = im.convert('RGBA')
        pix = im.load()
        all_pix = []
        for i in range(im.size[0]):
            for j in range(im.size[1]):
                all_pix.append(pix[i, j])

        # Get a unique list of pixels
        unique_colors = set(all_pix)

        # This data has a couple of fill values (because I added them) and
        # covers the entire range of colors.
        self.assertEqual(
            len(unique_colors),
            len(colors) +
            1,
            "Correct number of colors: is %d, should be %d." %
            (len(unique_colors),
             len(all_colors)))

        # make sure that the colors from the image are in the colorbar
        rgba_to_hex = lambda color: "#%.2x%.2x%.2x (%.2x)" % (color[0],
                                                              color[1],
                                                              color[2],
                                                              color[3])

        for color in unique_colors:
            self.assertTrue(
                color in all_colors,
                "Color %s is in the colorbar" %
                rgba_to_hex(color))


def readSld(sld_file):
    # function to convert convert colors to rgb
    hex_to_rgba = lambda hex_, alpha: (int(hex_[1:3], 16),
                                       int(hex_[3:5], 16),
                                       int(hex_[5:], 16),
                                       alpha)

    xml = etree.parse(sld_file)
    namespaces = {"se": "http://www.opengis.net/se"}

    nodes = xml.xpath("//se:Value", namespaces=namespaces)
    colors = [hex_to_rgba(node.text, 255) for node in nodes]

    fallback_color = None
    nodes = xml.xpath("//se:Categorize", namespaces=namespaces)
    if len(nodes) > 0:
        fallback_color = hex_to_rgba(nodes[0].get("fallbackValue"), 0)

    return(colors, fallback_color)

if __name__ == "__main__":
    unittest.main()
