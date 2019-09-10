"""
Tests the get_query_params function in cgi_utils.py.

NOTE: This is not a great unit test. The cgi_utils.get_query_params function
needs cgi_untaint.pl to be in the path. cgi_untaint.pl needs to be in a
giovanni installation to get configuration out of giovanni.cfg.
"""

import unittest
import cgi_utils as cu


class CgiUtilsTest(unittest.TestCase):

    def test_simple(self):
        qstring = "service=ArAvTs"

        params = cu.get_query_params(qstring)
        self.assertDictEqual(params, {'service': ['ArAvTs']})

    def test_encoded(self):
        """
        Do a test with characters that need to be encoded
        """
        qstring = "variable=TRMM_3B42_Daily_7_precipitation%2CTRMM_3B42RT_Daily_7_precipitation&destinationUnits=mm%2Fhr"

        params = cu.get_query_params(qstring)
        self.assertDictEqual(
            params,
            {
                'variable': ['TRMM_3B42_Daily_7_precipitation,TRMM_3B42RT_Daily_7_precipitation'],
                'destinationUnits': ['mm/hr']})


if __name__ == "__main__":
    unittest.main()
