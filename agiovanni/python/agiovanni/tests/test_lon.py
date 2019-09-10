'''
Created on Oct 19, 2015

Tests agiovanni.lon.

@author: csmit
'''
import unittest
import numpy as np
import numpy.ma as ma
import re
import agiovanni.lon as lon


class Test(unittest.TestCase):

    def testCanonicalLongitude(self):
        '''
        Test agiovanni.lon.get_canonical_longitude
        '''
        lons = [-190.0, -1000.0, -80, 0, 180.0, 185.0]
        canon = lon.get_canonical_longitude(lons)
        correct = [170.0, 80, -80, 0, -180.0, -175.0]
        np.testing.assert_almost_equal(
            canon,
            np.array(correct),
            3,
            "Longitudes not canonical",
            True)

    def testGetResolution(self):
        '''
        Test agiovanni.long.get_resolution
        '''

        self.assertAlmostEqual(
            lon.get_resolution([0.5, 1.5, 2.5]),
            1.0,
            2,
            "Simple resolution calculation")
        self.assertAlmostEqual(
            lon.get_resolution([0.5, 1.5]),
            1.0,
            2,
            "Resolution of two points")
        self.assertAlmostEqual(
            lon.get_resolution([179.5, -179.5]),
            1.0,
            2,
            "Resolution over 180")
        self.assertAlmostEqual(
            lon.get_resolution([178.5, -178.5, -176.5]),
            2.0,
            2,
            "Resolution over 180")

    def testOver180(self):
        '''
        Tests agiovanni.lon.goes_over_180
        '''
        inds = lon.goes_over_180([-180, -170, -160])
        self.assertEqual(inds, [], "Doesn't go over the 180 meridian")
        inds = lon.goes_over_180([170, 180])
        self.assertEqual(inds, [1], "Does go over 180 meridian")
        inds = lon.goes_over_180([150, 170, 190])
        self.assertEqual(inds, [2], "Does go over 180 meridian")
        inds = lon.goes_over_180([10, 100, 190, 280, 370, 460, 550])
        self.assertEqual(inds, [2, 6], "Goes over 180 meridian twice")

    def runExtendTest(
            self, inputLons, inputData, fillValue, outputLons, outputData):
        '''
        Runs a test against agiovanni.lon.extend_for_map_server
        '''
        inputData = stringToMaskedArray(inputData, fillValue)
        outputData = stringToMaskedArray(outputData, fillValue)
        (testLons, testData) = lon.extend_for_map_server(inputLons, inputData,
                                                         fillValue)
        np.testing.assert_almost_equal(
            testLons,
            outputLons,
            3,
            "Longitudes not normalized correctly",
            True)

        np.testing.assert_almost_equal(
            testData,
            outputData,
            3,
            "Output data correct",
            True)

    def runNormalizeTest(
            self, inputLons, inputData, fillValue, outputLons, outputData,
            func=lon.normalize):
        '''
        Runs a normalization test. By default, it runs agiovanni.lon.normalize.
        '''
        inputData = stringToMaskedArray(inputData, fillValue)
        outputData = stringToMaskedArray(outputData, fillValue)
        (testLons, testData) = func(inputLons, inputData, fillValue)
        np.testing.assert_almost_equal(
            testLons,
            outputLons,
            3,
            "Longitudes not normalized correctly",
            True)

        np.testing.assert_almost_equal(
            testData,
            outputData,
            3,
            "Output data correct",
            True)

    def testExtendSimple(self):
        '''
        Test the map server extension with something that doesn't need to be
        extended.
        '''
        lons = np.array([150, 160], dtype=float)
        data = '''
55.2 65.3
20.1 96.3
75.3 88.3
99.9 99.2
41.1 83.9
'''
        fillValue = -100
        self.runExtendTest(lons, data, fillValue, lons, data)

    def testNeedsExtendRounding(self):
        '''
        Tests the code to make sure that round errors won't erroneously make
        the code try to extend the data.
        '''
        # these longitudes will be just slightly off
        lons = np.linspace(-179.501, 179.501, 360)
        # This data is the wrong shape, but it shouldn't matter because the
        # data shouldn't be touched.
        data = '''
0.0 0.0 0.0
'''
        fillValue = -999
        self.runExtendTest(lons, data, fillValue, lons, data)
        pass

    def testNeedsExtendRight(self):
        '''
        Test something where we do need to copy over data
        '''

        lons = np.array([108, -180, -108], float)
        data = '''
 0.0 11.1 12.4
 1.2  4.2    _
 2.2    _ 15.5
'''
        fillValue = -1999
        outputLons = np.array([-180, -108, -36, 36, 108, 180], float)
        outputData = '''
11.1 12.4    _    _ 0.0 11.1
 4.2    _    _    _ 1.2  4.2
   _ 15.5    _    _ 2.2    _
'''
        self.runExtendTest(lons, data, fillValue, outputLons, outputData)

    def testNeedsExtendLeft(self):
        '''
        Test something where we do need to copy over data
        '''

        lons = np.array([107, 179, -109], float)
        data = '''
 0.0 11.1 12.4
 1.2  4.2    _
 2.2    _ 15.5
'''
        fillValue = -1999
        outputLons = np.array([-181, -109, -37, 35, 107, 179], float)
        outputData = '''
11.1 12.4    _    _ 0.0 11.1
 4.2    _    _    _ 1.2  4.2
   _ 15.5    _    _ 2.2    _
'''
        self.runExtendTest(lons, data, fillValue, outputLons, outputData)

    def testTwoLons(self):
        '''
        Test the code will work with only two longitudes.
        '''
        lons = np.array([160, -160], dtype=float)
        data = '''
55.2 65.3
20.1 96.3
75.3 88.3
99.9 99.2
41.1 83.9
'''
        fillValue = -100

        outputLons = np.array(
            [-160, -120, -80, -40, 0, 40, 80, 120, 160], dtype=float)
        outputData = """
65.3 _    _    _    _    _    _    _   55.2
96.3 _    _    _    _    _    _    _   20.1
88.3 _    _    _    _    _    _    _   75.3
99.2 _    _    _    _    _    _    _   99.9
83.9 _    _    _    _    _    _    _   41.1
"""
        self.runNormalizeTest(lons, data, fillValue, outputLons, outputData)

    def testDataOver180(self):
        '''
        Perform a test where the data goes over the 180 meridian.
        '''
        lons = np.array([170, -170, -150, -130], dtype=float)
        data = '''
1.0 1.1 1.2 1.3
1.4 1.5 2.5 2.9
3.3 _   _   4.5
'''
        fillValue = -999.99

        outputLons = np.array([-170, -150, -130, -110, -90, -70, -50, -30, -10,
                               10, 30, 50, 70, 90, 110, 130, 150, 170],
                              dtype=float)
        outputData = """
1.1 1.2 1.3 _    _    _    _    _    _    _    _    _    _    _    _    _    _   1.0
1.5 2.5 2.9 _    _    _    _    _    _    _    _    _    _    _    _    _    _   1.4
_   _   4.5 _    _    _    _    _    _    _    _    _    _    _    _    _    _   3.3
"""
        self.runNormalizeTest(lons, data, fillValue, outputLons, outputData)
        # Test against normalize_if_needed. This definitely needs to be
        # normalized.
        self.runNormalizeTest(
            lons,
            data,
            fillValue,
            outputLons,
            outputData,
            lon.normalize_if_needed)

    def testEasyExtend(self):
        '''
        Do a simple test where we just have to extend the data out to +180.
        '''
        lons = np.array([-170.0, -110.0, -50.0, 10.0])
        data = """
0.1  0.2  0.3  0.4
0.5  0.6  0.7  0.8
0.9  1.0  1.1  1.2
_    _    1.4  1.5
"""

        fillValue = -999.0

        outputLons = np.array([-170.0, -110.0, -50.0, 10.0, 70.0, 130.0])
        outputData = """
0.1  0.2  0.3  0.4  _  _
0.5  0.6  0.7  0.8  _  _
0.9  1.0  1.1  1.2  _  _
_    _    1.4  1.5  _  _
"""
        self.runNormalizeTest(lons, data, fillValue, outputLons, outputData)
        # test to make sure this is NOT normalized when we call
        #'normalize_if_needed'
        self.runNormalizeTest(
            lons,
            data,
            fillValue,
            lons,
            data,
            lon.normalize_if_needed)


def stringToMaskedArray(str_, fillValue):
    '''
    Helper function to convert a string representation of the data into a
    masked array.
    '''
    lines = str_.splitlines()
    # remove lines that are just whitespace
    lines = filter(lambda x: not re.match(r'^\s*$', x), lines)
    nlats = len(lines)
    values = [line.split() for line in lines]
    nlons = len(values[0])
    data = np.empty((nlats, nlons), dtype=float)
    mask = np.empty((nlats, nlons), dtype=bool)
    for lat in range(nlats):
        for lon in range(nlons):
            if values[lat][lon] == '_':
                data[lat][lon] = fillValue
                mask[lat][lon] = True
            else:
                data[lat][lon] = float(values[lat][lon])
                mask[lat][lon] = False

    return ma.masked_array(data, mask=mask, fill_value=fillValue)

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
