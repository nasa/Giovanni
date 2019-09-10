'''
Created on Jan 12, 2016

@author: csmit
'''
import unittest
import agiovanni.area_stats as area_stats
import numpy as np
import numpy.ma as ma
from netCDF4 import Dataset
import os


class Test(unittest.TestCase):

    def testAllFill(self):
        '''
        Tests that the code can handle data that is all masked values
        '''
        data = ma.masked_array(data=[[1.0, 2.0], [3.0, 4.0], [5.0, 6.0]], mask=[
                               [True, True], [True, True], [True, True]])
        weights = np.array([[0.1, 0.2], [0.3, 0.4], [0.5, 0.6]])
        stats = area_stats.compute_statistics(
            data, weights=weights)

        self.assertEqual(stats["count"], 0, "correct count value")
        self.assertTrue(stats["min"].mask.all(), "correct min value")
        self.assertTrue(stats["max"].mask.all(), "correct max value")
        self.assertTrue(stats["avg"].mask.all(), "correct average")
        self.assertTrue(
            stats["stddev"].mask.all(),
            "correct standard deviation")

    def testShapeFromNetcdf(self):
        '''
        Test that mask file average matches nco.
        '''
        dir_ = os.path.dirname(__file__)
        in_file = os.path.join(
            dir_,
            "test_area_stats",
            "canada.AIRX3STD_006_SurfAirTemp_A.20050101.nc")
        with Dataset(in_file, 'r') as nc:
            data = nc["AIRX3STD_006_SurfAirTemp_A"][:]
            weights = nc["shape_mask"][:]

        stats = area_stats.compute_statistics(data, weights=weights)
        self.assertAlmostEqual(stats["avg"], 254.1564, 4, "correct average")

    def test3D(self):
        '''
        Test that files with a height dimension work
        '''
        dir_ = os.path.dirname(__file__)
        in_file = os.path.join(
            dir_,
            "test_area_stats",
            "withHeight.nc")
        with Dataset(in_file, 'r') as nc:
            data = nc["MAIMCPASM_5_2_0_RH"][:]
            lat = nc["lat"][:]

        out = area_stats.compute_statistics(
            data,
            axis=(
                2,
                3),
            lat=lat,
            lat_dim=2)
        correct_avg = np.array([0.7680209, 0.702123, 0.6754904]).reshape(1, 3)
        self.helperCompareArrays(
            out['avg'],
            correct_avg,
            5,
            "Correct averages")

        correct_count = np.array([30, 30, 30]).reshape(1, 3)
        self.helperCompareArrays(
            out['count'],
            correct_count,
            5,
            "Correct counts")

        correct_max = np.array([0.8671875, 0.8378906, 0.8457031]).reshape(1, 3)
        self.helperCompareArrays(out['max'], correct_max, 5, "Correct maximum")

        correct_min = np.array([0.5751953, 0.4355469, 0.3867188]).reshape(1, 3)
        self.helperCompareArrays(out['min'], correct_min, 5, "Correct minimum")

        correct_stddev = np.array(
            [0.08910514, 0.1297871, 0.1456206]).reshape(1, 3)
        self.helperCompareArrays(
            out['stddev'],
            correct_stddev,
            5,
            "Correct standard deviation")

        # To get the correct values, I ran time series at the 500, 450, and 400
        # height levels. These are the values from those time series:

        # 500:
        # avg: 0.7680209
        # count: 30
        # max: 0.8671875
        # min: 0.5751953
        # stddev: 0.08910514

        # 450:
        # avg: 0.702123
        # count: 30
        # max: 0.8378906
        # min: 0.4355469
        # stddev: 0.1297871

        # 400:
        # avg: 0.6754904
        # count: 30
        # max: 0.8457031
        # min: 0.3867188
        # stddev: 0.1456206

    def testFromNetcdf(self):
        '''
        Test that longitude-weighted statistics match nco.
        '''
        dir_ = os.path.dirname(__file__)
        in_file = os.path.join(
            dir_,
            "test_area_stats",
            "subsetted.AIRX3STD_006_SurfAirTemp_A.20050101.nc")
        with Dataset(in_file, 'r') as nc:
            data = nc["AIRX3STD_006_SurfAirTemp_A"][:]
            lat = nc["lat"][:]

        stats = area_stats.compute_statistics(data, lat=lat, lat_dim=1)
        self.assertEquals(stats["count"], 16450, "correct count")
        self.assertAlmostEqual(stats["min"], 223.9375, 4, "correct min")
        self.assertAlmostEqual(stats["max"], 307.9375, 4, "correct max")
        self.assertAlmostEqual(stats["avg"], 287.2682, 4, "correct average")
        self.assertAlmostEqual(
            stats["stddev"],
            14.91378,
            4,
            "correct standard deviation")

    def testOptions(self):
        '''
        Test to make sure that we can optionally NOT calculate some statistics
        '''
        data = ma.masked_array(data=[[1.0, 2.0], [3.0, 4.0], [5.0, 6.0]], mask=[
                               [False, False], [False, True], [False, True]])
        weights = np.array([[0.1, 0.2], [0.3, 0.4], [0.5, 0.6]])
        stats = area_stats.compute_statistics(
            data,
            weights=weights,
            stddev=False,
            min_=False,
            max_=False,
            count=False)

        self.assertFalse('count' in stats, "count not calculated")
        self.assertFalse('min' in stats, "min not calculated")
        self.assertFalse('max' in stats, "max not calculated")
        self.assertAlmostEqual(stats["avg"], 3.5454545, 7, "correct average")
        self.assertFalse(
            'stddev' in stats,
            "standard deviation not calculated")

    def testWithZeroWeights(self):
        '''
        Test that weights valued zero are not counted.
        '''
        data = ma.masked_array(data=[[1.0, 2.0], [3.0, 4.0], [5.0, 6.0]], mask=[
                               [False, False], [False, True], [False, True]])
        weights = np.array([[0.0, 0.2], [0.3, 0.4], [0.5, 0.6]])
        stats = area_stats.compute_statistics(data, weights=weights)

        self.assertEqual(stats["count"], 3, "correct count value")
        self.assertEquals(stats["min"], 2.0, "correct min value")
        self.assertEquals(stats["max"], 5.0, "correct max value")
        self.assertAlmostEqual(
            stats["avg"],
            3.7999999999999998,
            7,
            "correct average")
        self.assertAlmostEqual(
            stats["stddev"],
            1.2489995996796797,
            7,
            "correct standard deviation")

    def testBasicLongitude(self):
        '''
        Test longitude-weighted statistics.
        '''
        data = ma.masked_array(data=[[1.0, 2.0], [3.0, 4.0], [5.0, 6.0]], mask=[
                               [False, False], [False, True], [False, True]])
        lats = np.array([0, 10.0, 20.0])
        stats = area_stats.compute_statistics(data, lat=lats, lat_dim=0)

        self.assertEqual(stats["count"], 4, "correct count value")
        self.assertEquals(stats["min"], 1.0, "correct min value")
        self.assertEquals(stats["max"], 5.0, "correct max value")
        self.assertAlmostEqual(
            stats["avg"],
            2.7144567074295733,
            7,
            "correct average")
        self.assertAlmostEqual(
            stats["stddev"],
            1.466384330453181,
            7,
            "correct standard deviation")

    def testBasicWeights(self):
        '''
        Simple test of statistics
        '''
        data = ma.masked_array(data=[[1.0, 2.0], [3.0, 4.0], [5.0, 6.0]], mask=[
                               [False, False], [False, True], [False, True]])
        weights = np.array([[0.1, 0.2], [0.3, 0.4], [0.5, 0.6]])
        stats = area_stats.compute_statistics(data, weights=weights)

        self.assertEqual(stats["count"], 4, "correct count value")
        self.assertEquals(stats["min"], 1.0, "correct min value")
        self.assertEquals(stats["max"], 5.0, "correct max value")
        self.assertAlmostEqual(stats["avg"], 3.5454545, 7, "correct average")
        self.assertAlmostEqual(
            stats["stddev"],
            1.4373989,
            7,
            "correct standard deviation")

    def testAddAxesBack(self):
        '''
        Tests the _add_axes_back function.
        '''
        back = area_stats._add_axes_back(ma.masked, (1, 2))
        correct = ma.masked_array(data=np.zeros((1, 1)), mask=True)
        self.helperCompareArrays(
            back,
            correct,
            1,
            "singleton masked constant")

        back = area_stats._add_axes_back(ma.masked_array([1], mask=True), 1)
        correct = ma.masked_array(np.ones((1, 1)), mask=True)
        self.helperCompareArrays(
            back,
            correct,
            1,
            "1-element 1-D array with masked value")

        back = area_stats._add_axes_back(1, 0)
        correct = np.array([1])
        self.helperCompareArrays(back, correct, 1, "singleton constant")

        back = area_stats._add_axes_back(1, (1, 2))
        correct = np.array([1]).reshape(1, 1)
        self.helperCompareArrays(back, correct, 1, "1-element array correct")

        arr = np.arange(4).reshape(2, 2)
        arr = ma.masked_array(data=arr, mask=[[True, False], [False, False]])
        back = area_stats._add_axes_back(arr, 0)
        correct = ma.masked_array(
            data=np.array([arr.data]), mask=np.array([arr.mask]))
        self.helperCompareArrays(back, correct, 1, "Arrays are equal")

        arr = ma.masked_array(np.arange(4))
        back = area_stats._add_axes_back(arr, (1, 2))
        correct = ma.masked_array(np.arange(4).reshape(4, 1, 1))
        self.helperCompareArrays(back, correct, 1, "Arrays are equal")

    def helperCompareArrays(self, first, second, decimal, msg):
        '''
        There is no obvious way to compare masked arrays nicely. This is my
        attempt at a comparison.
        '''

        self.assertSequenceEqual(
            first.shape,
            second.shape,
            "Correct shape: %s" %
            msg)

        if(ma.count(first) == 0 and ma.count(second) == 0):
            # if they are the same shape and have no data, they are the same
            return

        self.assertTrue(
            ma.allclose(
                first,
                second,
                atol=decimal),
            "Values: %s" %
            msg)
        try:
            np.testing.assert_array_almost_equal(
                ma.getmaskarray(first),
                ma.getmaskarray(second),
                decimal=decimal,
                err_msg=msg,
                verbose=True)
        except AssertionError as e:
            self.assertRaises(e)

if __name__ == "__main__":
    unittest.main()
