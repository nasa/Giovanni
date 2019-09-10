#!/bin/env python
"""Unit tests for the g4_shp_casecorrect.py script."""

__author__ = 'Daniel da Silva <Daniel.e.daSilva@nasa.gov>'

import os
import sys
import unittest

sys.path.insert(0, os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    '..', 'scripts'))
import g4_shp_casecorrect as CC


class CaseCorrectTest(unittest.TestCase):
    
    def test_all_cap_string(self):
        self.assertEqual('United States',
                         CC.correct_case('UNITED STATES'))
        self.assertEqual('Mexico',
                         CC.correct_case('MEXICO'))

    def test_parenthesis(self):
        self.assertEqual('Norfolk Island (Australia)',
                         CC.correct_case('Norfolk Island (AUSTRALIA)'))
        self.assertEqual('Niue (New Zealand)',
                         CC.correct_case('Niue (NEW ZEALAND)'))
    
    def test_acceptable_capitalizations(self):
        test_strings = [
            'Puerto Rico (US)',
            'Virgin Islands (UK)',
            'Virgin Islands (US)',
        ]
        
        for test_string in test_strings:
            self.assertEqual(test_string,  CC.correct_case(test_string))


if __name__ == '__main__':
    unittest.main()


                
