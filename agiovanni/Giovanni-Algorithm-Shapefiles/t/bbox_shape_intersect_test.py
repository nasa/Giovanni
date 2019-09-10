'''
Tests agiovanni.intersect code.
'''

__author__ = \
    'Christine Smit <christine.e.smit@nasa.gov> Michael Nardozzi <michael.a.nardozzi@nasa.gov>'

import unittest
import subprocess
import os

import agiovanni.intersect as intersect


class Test(unittest.TestCase):

    """Tests the intersection code."""

    def setUp(self):
        test_dir = os.path.dirname(__file__)
        self.test_file_dir = os.path.join(test_dir, 'd')

    def testBboxShapeIntersect(self):

        us_states = os.path.join(self.test_file_dir,
                                 'tl_2014_us_state.shp')
        countries = os.path.join(self.test_file_dir,
                                 'state_dept_countries.shp')

       # The first argument passed to intersectBboxes.pl is the users bounding box
       # The second argument passed to intersectBboxes.pl is the data bbox
       # The result bbox is the intersection of the users bounding box and the data bbox 

       # Bounding box over Maryland, NLDAS data with Maryland Shape
        bbox_intersect_nldas_md = \
            'intersectBboxes.pl --bbox -79.6729,37.6026,-74.8608,40.0086 --bbox -125,25,-67,53'
        process1 = subprocess.Popen(bbox_intersect_nldas_md,
                                    stdout=subprocess.PIPE,
                                    stderr=None, shell=True)
        output1 = process1.communicate()
        print 'Intersection of users bounding box and data bounding box is: ' \
            + output1[0] + '\n'

        # Bounding box over Texas, NLDAS data with Maryland Shape
        bbox_intersect_nldas_tx = \
            'intersectBboxes.pl --bbox -106.0291,26.5961,-94.0759,37.4945 --bbox -125,25,-67,53'
        process2 = subprocess.Popen(bbox_intersect_nldas_tx,
                                    stdout=subprocess.PIPE,
                                    stderr=None, shell=True)
        output2 = process2.communicate()
        print 'Intersection of users bounding box and data bounding box is: ' \
            + output2[0] + '\n'

        # Bounding box over United States and Australia, NLDAS data with Australia Shape
        bbox_intersect_nldas_usaust = \
            'intersectBboxes.pl --bbox 88.5938,-47.6953,-40.7812,66.9141 --bbox -125,25,-67,53'
        process3 = subprocess.Popen(bbox_intersect_nldas_usaust,
                                    stdout=subprocess.PIPE,
                                    stderr=None, shell=True)
        output3 = process3.communicate()
        print 'Intersection of users bounding box and data bounding box is: ' \
            + output3[0] + '\n'

        # Bounding box over United States, NLDAS data with Australia Shape
        bbox_intersect_nldas_aust = \
            'intersectBboxes.pl --bbox -127.9687,24.375,-67.1484,53.9063 --bbox -125,25,-67,53'
        process4 = subprocess.Popen(bbox_intersect_nldas_aust,
                                    stdout=subprocess.PIPE,
                                    stderr=None, shell=True)
        output4 = process4.communicate()
        print 'Intersection of users bounding box and data bounding box is: ' \
            + output4[0] + '\n'


       # Bounding box over 180 meridian and United States, NLDAS data with Australia Shape
        bbox_intersect_nldas_antimeridian = \
            'intersectBboxes.pl --bbox 168.4204,15.8496,-68.8843,64.3652 --bbox -125,25,-67,53'
        process5 = subprocess.Popen(bbox_intersect_nldas_antimeridian,
                                    stdout=subprocess.PIPE,
                                    stderr=None, shell=True)
        output5 = process5.communicate()
        print 'Intersection of users bounding box and data bounding box is: ' \
            + output5[0] + '\n'

       # NLDAS data with Australia Shape; user does not select a bounding box
        bbox_intersect_nldas_aust_nobbox = \
            'intersectBboxes.pl --bbox -125,25,-67,53'
        process6 = subprocess.Popen(bbox_intersect_nldas_aust_nobbox,
                                    stdout=subprocess.PIPE,
                                    stderr=None, shell=True)
        output6 = process6.communicate()
        print 'Intersection of users bounding box and data bounding box is: ' \
            + output6[0] + '\n'


        self.assertTrue(intersect.intersects(output1[0], us_states,
                        'shp_4'),
                        'Intersection of users bounding box over Maryland and data bounding box (NLDAS) intersects with the Maryland shape'
                        )

        self.assertFalse(intersect.intersects(output2[0], us_states,
                         'shp_4'),
                         'Intersection of users bounding box over Texas and data bounding box (NLDAS) does not intersect with the Maryland shape'
                         )

        self.assertFalse(intersect.intersects(output3[0], countries,
                         'shp_15'),
                         'Intersection of users bounding box over United States/Australia and data bounding box (NLDAS) does not intersect with the Australia shape'
                         )

        self.assertFalse(intersect.intersects(output4[0], countries,
                         'shp_15'),
                         'Intersection of users bounding box over United States and data bounding box (NLDAS) does not intersect with the Australia shape'
                         )

        self.assertFalse(intersect.intersects(output5[0], countries,
                         'shp_15'),
                         'Intersection of users bounding box over the 180 Meridian and data bounding box (NLDAS) does not intersect with the Australia shape'
                         )
        self.assertFalse(intersect.intersects(output6[0], countries,
                         'shp_15'),
                         'Intersection of data bounding box (NLDAS) does not intersect with the Australia shape'
                         )


if __name__ == "__main__":
    unittest.main()
