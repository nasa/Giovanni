#!/bin/env python

import os
import sys
import tempfile
import unittest

import agiovanni.alg

sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'scripts'))
import seasonDropper


def getMonthAndYear(dataMonthString):
    year = dataMonthString[0:4]
    month = dataMonthString[-2:]

    return {'month': month, 'year': year}
    pass


class SeasonTest(unittest.TestCase):

    def setUp(self):
        self.inputFile = tempfile.NamedTemporaryFile()
        self.outputFileName = self.inputFile.name + '.out'

    def tearDown(self):
        if os.path.exists(self.outputFileName):
            os.remove(self.outputFileName)

    def createStrings(self, season, n):
        startYear = 1980

        groupMonthVal = {
            'DJF': (12, 1, 2),
            'MAM': (3, 4, 5),
            'JJA': (6, 7, 8),
            'SON': (9, 10, 11)
        }[season]
        groupYearOffset = (-1, 0, 0) if season == 'DJF' else (0, 0, 0)

        dataMonthStrings = []
        for i in range(0, n):
            for j in range(0, 3):
                dataMonthStrings.append(
                    "%.4d%.2d" % (startYear + i + groupYearOffset[j],
                              groupMonthVal[j]))

        return dataMonthStrings
    
    def testMAMNoDrops(self, n=10):

        agiovanni.alg.write_file_list(
            self.inputFile.name, self.createStrings('MAM', n))

        devnull = open('/dev/null', 'w')
        argv = [
            '-f', self.inputFile.name,
            '-o', self.outputFileName,
            '-v', 'varNamePlaceholder',
            '-g', 'SEASON=DJF',
        ]

        numDropped = seasonDropper.main(argv, devnull, devnull,
                                        getMonthAndYear=getMonthAndYear)
        self.assertEqual(numDropped, 0)
        self.assertTrue(os.path.exists(self.outputFileName))

        file_list = agiovanni.alg.read_file_list(self.outputFileName)
        self.assertEqual(3 * n, len(file_list))
    
    def testMAMSomeDrops(self):
        # this is basically JIRA ticket FEDGIANNI-1215
        
        fileList = ['20070301','20070401','20070501',
                    '20080401','20080501',
                    '20090301','20090401',
                    '20100301','20100401','20100501']

        agiovanni.alg.write_file_list(self.inputFile.name, fileList);
        
        
        devnull = open('/dev/null', 'w')
        argv = [
            '-f', self.inputFile.name,
            '-o', self.outputFileName,
            '-v', 'varNamePlaceholder',
            '-g', 'SEASON=DJF',
        ]

        numDropped = seasonDropper.main(argv, devnull, devnull,
                                        getMonthAndYear=getMonthAndYear)
        
        self.assertEqual(4, numDropped)
        self.assertTrue(os.path.exists(self.outputFileName))
        
        fileList = agiovanni.alg.read_file_list(self.outputFileName)
        self.assertEqual(6,len(fileList));

    def testDJFNoDrops(self, n=10):

        agiovanni.alg.write_file_list(
            self.inputFile.name, self.createStrings('DJF', n))

        devnull = open('/dev/null', 'w')
        argv = [
            '-f', self.inputFile.name,
            '-o', self.outputFileName,
            '-v', 'varNamePlaceholder',
            '-g', 'SEASON=DJF',
        ]

        numDropped = seasonDropper.main(argv, devnull, devnull,
                                        getMonthAndYear=getMonthAndYear)
        self.assertEqual(numDropped, 0)
        self.assertTrue(os.path.exists(self.outputFileName))

        file_list = agiovanni.alg.read_file_list(self.outputFileName)
        self.assertEqual(3 * n, len(file_list))

    def testDJFSomeDrops(self, n=10):  # n must be even
        file_list = self.createStrings('DJF', n)
        file_list.pop(3 * n / 2)

        agiovanni.alg.write_file_list(self.inputFile.name, file_list)

        devnull = open('/dev/null', 'w')
        argv = [
            '-f', self.inputFile.name,
            '-o', self.outputFileName,
            '-v', 'varNamePlaceholder',
            '-g', 'SEASON=DJF',
        ]

        numDropped = seasonDropper.main(argv, devnull, devnull,
                                        getMonthAndYear=getMonthAndYear)

        self.assertEqual(numDropped, 2)
        self.assertTrue(os.path.exists(self.outputFileName))

        file_list = agiovanni.alg.read_file_list(self.outputFileName)
        self.assertEqual(3 * (n - 1), len(file_list))


class MonthTest(unittest.TestCase):

    def setUp(self):
        self.inputFile = tempfile.NamedTemporaryFile()
        self.outputFileName = self.inputFile.name + '.out'

    def tearDown(self):
        if os.path.exists(self.outputFileName):
            os.remove(self.outputFileName)

    def testMonth(self):
        agiovanni.alg.write_file_list(self.inputFile.name,
                                      ['200103',
                                       '200203',
                                       '200303',
                                       '200403'])

        devnull = open('/dev/null', 'w')
        argv = [
            '-f', self.inputFile.name,
            '-o', self.outputFileName,
            '-v', 'varNamePlaceholder',
            '-g', 'MONTH=3'
        ]

        numDropped = seasonDropper.main(argv, devnull, devnull,
                                        getMonthAndYear=getMonthAndYear)
        self.assertEqual(numDropped, 0)
        self.assertTrue(os.path.exists(self.outputFileName))

        file_list = agiovanni.alg.read_file_list(self.outputFileName)
        self.assertEqual(4, len(file_list))


if __name__ == '__main__':
    unittest.main()
