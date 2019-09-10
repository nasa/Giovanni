"""
Tests for the agiovanni.nco module.
"""

import unittest
import os
import tempfile
import shutil
import re
import subprocess

from agiovanni import nco
from agiovanni import netcdf


class IntegrationTest(unittest.TestCase):

    """test_netcdf.py: Test the netcdf library functionality."""

    def setUp(self):
        self.dir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.dir)

    def testNcGenAndDump(self):
        """
        testNcGenAndDump: This tests ncgen, ncdump, and diff_nc_files.
        """

        cdl = """netcdf g4.dimensionAveraged.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20070101-20070531.180W_90S_180E_90N {
dimensions:
    lat = 180 ;
variables:
    float OMAERUVd_003_FinalAerosolAbsOpticalDepth500(lat) ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:_FillValue = -1.267651e+30f ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:units = "1" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:title = "Final Aerosol Absorption Optical Depth at 500 nm" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:UniqueFieldDefinition = "Aura-Shared" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:missing_value = -1.267651e+30f ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:origname = "FinalAerosolAbsOpticalDepth500" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:fullnamepath = "/HDFEOS/GRIDS/Aerosol NearUV Grid/Data Fields/FinalAerosolAbsOpticalDepth500" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:orig_dimname_list = "XDim " ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:standard_name = "finalaerosolabsopticaldepth500" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:quantity_type = "Component Aerosol Optical Depth" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:product_short_name = "OMAERUVd" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:product_version = "003" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:long_name = "Aerosol Absorption Optical Depth 500 nm" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:coordinates = "lat" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:cell_methods = "time: mean time: mean lon: mean" ;
    float lat(lat) ;
        lat:units = "degrees_north" ;
        lat:standard_name = "latitude" ;
        lat:long_name = "Latitude" ;
    int time ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
        time:cell_methods = "time: mean time: mean" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2007-01-01T00:00:00Z" ;
        :end_time = "2007-05-31T23:59:59Z" ;
        :NCO = "4.4.4" ;
        :title = "Zonal Mean of Aerosol Absorption Optical Depth 500 nm daily 1 deg. [OMI OMAERUVd v003] over 2007-01-01 - 2007-05-31, Region 180W, 90S, 180E, 90N " ;
        :userstartdate = "2007-01-01T00:00:00Z" ;
        :userenddate = "2007-05-31T23:59:59Z" ;
        :plot_hint_title = "Zonal Mean of Aerosol Absorption Optical Depth 500 nm daily 1 deg. [OMI OMAERUVd v003]" ;
        :plot_hint_subtitle = "over 2007-01-01 - 2007-05-31, Region 180W, 90S, 180E, 90N " ;
data:

 OMAERUVd_003_FinalAerosolAbsOpticalDepth500 = _, _, _, _, _, _, _, _, _, _,
    _, 0.005732692, 0.006581111, 0.007075, 0.009131111, 0.004580555,
    0.005465476, 0.007679146, 0.009428572, 0.01065788, 0.01075311,
    0.01020044, 0.01059343, 0.01057464, 0.01093628, 0.01054243, 0.01040399,
    0.01024107, 0.010555, 0.01058991, 0.01082234, 0.01120079, 0.01109179,
    0.01098205, 0.01090842, 0.01067376, 0.01084355, 0.0105546, 0.01102721,
    0.0108445, 0.01062187, 0.01086002, 0.01097366, 0.01089651, 0.0108049,
    0.0111255, 0.01132336, 0.01183876, 0.01190265, 0.01238493, 0.01284299,
    0.01273277, 0.01274212, 0.01318873, 0.0133806, 0.01266411, 0.0123679,
    0.01223416, 0.0122082, 0.01239032, 0.01283799, 0.01264289, 0.01335857,
    0.01406726, 0.0136835, 0.01354076, 0.01346605, 0.01407613, 0.01449858,
    0.01540472, 0.01636874, 0.01727555, 0.01697236, 0.01710043, 0.01886979,
    0.02071303, 0.0209736, 0.02122237, 0.02191506, 0.02317924, 0.02311635,
    0.02437284, 0.02510679, 0.02756837, 0.02940871, 0.03088564, 0.03095269,
    0.03290334, 0.03656573, 0.04043462, 0.02227949, 0.0241449, 0.0256703,
    0.02667642, 0.02811306, 0.02749476, 0.02779504, 0.02673381, 0.02709048,
    0.02630195, 0.02669799, 0.02745636, 0.02823166, 0.0287596, 0.02966023,
    0.03021878, 0.02934904, 0.02881913, 0.02977417, 0.0290994, 0.02990918,
    0.02926073, 0.02920911, 0.02991091, 0.03026013, 0.03118533, 0.03071805,
    0.03067967, 0.03001351, 0.03018758, 0.02917851, 0.02880954, 0.02710553,
    0.02733052, 0.02530651, 0.02425399, 0.02319269, 0.02246948, 0.02213282,
    0.02045375, 0.0192234, 0.01820018, 0.0165542, 0.0151861, 0.01542374,
    0.01480468, 0.01349664, 0.01279164, 0.01236739, 0.01189257, 0.01247538,
    0.01188147, 0.01306759, 0.01346336, 0.01303782, 0.0130661, 0.01388488,
    0.01337894, 0.0126784, 0.0114906, 0.01030282, 0.008109493, 0.008321685,
    0.008804344, 0.009125766, 0.007295664, 0.008229486, 0.01352808,
    0.02181816, 0.02002032, 0.01834002, 0.01460644, 0.01919092, 0.02036057,
    0.01825572, 0.02255302, 0.02398033, 0.04331125, 0.1132933, 0.007104762,
    0, _, _, _, _, _, _, _, _, _ ;

 lat = -89.5, -88.5, -87.5, -86.5, -85.5, -84.5, -83.5, -82.5, -81.5, -80.5,
    -79.5, -78.5, -77.5, -76.5, -75.5, -74.5, -73.5, -72.5, -71.5, -70.5,
    -69.5, -68.5, -67.5, -66.5, -65.5, -64.5, -63.5, -62.5, -61.5, -60.5,
    -59.5, -58.5, -57.5, -56.5, -55.5, -54.5, -53.5, -52.5, -51.5, -50.5,
    -49.5, -48.5, -47.5, -46.5, -45.5, -44.5, -43.5, -42.5, -41.5, -40.5,
    -39.5, -38.5, -37.5, -36.5, -35.5, -34.5, -33.5, -32.5, -31.5, -30.5,
    -29.5, -28.5, -27.5, -26.5, -25.5, -24.5, -23.5, -22.5, -21.5, -20.5,
    -19.5, -18.5, -17.5, -16.5, -15.5, -14.5, -13.5, -12.5, -11.5, -10.5,
    -9.5, -8.5, -7.5, -6.5, -5.5, -4.5, -3.5, -2.5, -1.5, -0.5, 0.5, 1.5,
    2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5, 11.5, 12.5, 13.5, 14.5,
    15.5, 16.5, 17.5, 18.5, 19.5, 20.5, 21.5, 22.5, 23.5, 24.5, 25.5, 26.5,
    27.5, 28.5, 29.5, 30.5, 31.5, 32.5, 33.5, 34.5, 35.5, 36.5, 37.5, 38.5,
    39.5, 40.5, 41.5, 42.5, 43.5, 44.5, 45.5, 46.5, 47.5, 48.5, 49.5, 50.5,
    51.5, 52.5, 53.5, 54.5, 55.5, 56.5, 57.5, 58.5, 59.5, 60.5, 61.5, 62.5,
    63.5, 64.5, 65.5, 66.5, 67.5, 68.5, 69.5, 70.5, 71.5, 72.5, 73.5, 74.5,
    75.5, 76.5, 77.5, 78.5, 79.5, 80.5, 81.5, 82.5, 83.5, 84.5, 85.5, 86.5,
    87.5, 88.5, 89.5 ;

 time = 1174089600 ;
}
"""
        cdl_file = os.path.join(self.dir, "data.cdl")
        handle = open(cdl_file, 'w')
        handle.write(cdl)
        handle.close()

        # run ncgen
        nc_file = os.path.join(self.dir, "data.nc")
        netcdf.ncgen(cdl_file, nc_file)

        self.assertTrue(os.path.exists(nc_file), "Netcdf file created")

        # now dump it. If it wasn't really a netcdf file, this won't work!
        dump = netcdf.ncdump(nc_file)
        self.assertTrue(
            re.match("^netcdf.*{.*}\n$", dump, re.DOTALL), "Got something CDL-ish back out again")

        # now dump it as XML
        doc = netcdf.ncdump(nc_file, '-x')
        namespaces = {
            "nc": "http://www.unidata.ucar.edu/namespaces/netcdf/ncml-2.2"}

        self.assertEqual(doc.xpath(
            '/nc:netcdf/nc:dimension[@name="lat"]', namespaces=namespaces)[0].get('length'),
            "180", 'Got a node out')

        # run ncgen again with a different filename
        nc_file2 = os.path.join(self.dir, "newname.nc")
        netcdf.ncgen(cdl_file, nc_file2)

        # change the units to '1' for OMAERUVd_003_FinalAerosolAbsOpticalDepth500.
        # It's already 1, of course, but this will add to the history. Then we
        # can make sure the comparison works.
        nco.edit_attributes(nc_file2, nc_file2,
                            [{'att_name': 'units',
                              'var_name': 'OMAERUVd_003_FinalAerosolAbsOpticalDepth500',
                              'att_type': 'c',
                              'att_val': '1'}],
                            overwrite=True,
                            stderr=subprocess.PIPE,
                            stdout=subprocess.PIPE)

        (are_different, diff) = netcdf.diff_nc_files(nc_file, nc_file2)
        self.assertFalse(
            are_different, "NCO files are different: \n%s" % "\n".join(diff))

        out = netcdf.diff_nc_files(nc_file, nc_file2, ignore_history=False)
        self.assertTrue(out[0], "NCO files do have different history")

    def testGetAttribute(self):
        """
        This tests get_attribute
        """

        cdl = """netcdf g4.dimensionAveraged.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20070101-20070531.180W_90S_180E_90N {
dimensions:
    lat = 180 ;
variables:
    float OMAERUVd_003_FinalAerosolAbsOpticalDepth500(lat) ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:_FillValue = -1.267651e+30f ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:units = "1" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:title = "Final Aerosol Absorption Optical Depth at 500 nm" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:UniqueFieldDefinition = "Aura-Shared" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:missing_value = -1.267651e+30f ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:origname = "FinalAerosolAbsOpticalDepth500" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:fullnamepath = "/HDFEOS/GRIDS/Aerosol NearUV Grid/Data Fields/FinalAerosolAbsOpticalDepth500" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:orig_dimname_list = "XDim " ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:standard_name = "finalaerosolabsopticaldepth500" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:quantity_type = "Component Aerosol Optical Depth" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:product_short_name = "OMAERUVd" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:product_version = "003" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:long_name = "Aerosol Absorption Optical Depth 500 nm" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:coordinates = "lat" ;
        OMAERUVd_003_FinalAerosolAbsOpticalDepth500:cell_methods = "time: mean time: mean lon: mean" ;
    float lat(lat) ;
        lat:units = "degrees_north" ;
        lat:standard_name = "latitude" ;
        lat:long_name = "Latitude" ;
    int time ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
        time:cell_methods = "time: mean time: mean" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2007-01-01T00:00:00Z" ;
        :end_time = "2007-05-31T23:59:59Z" ;
        :NCO = "4.4.4" ;
        :title = "Zonal Mean of Aerosol Absorption Optical Depth 500 nm daily 1 deg. [OMI OMAERUVd v003] over 2007-01-01 - 2007-05-31, Region 180W, 90S, 180E, 90N " ;
        :userstartdate = "2007-01-01T00:00:00Z" ;
        :userenddate = "2007-05-31T23:59:59Z" ;
        :plot_hint_title = "Zonal Mean of Aerosol Absorption Optical Depth 500 nm daily 1 deg. [OMI OMAERUVd v003]" ;
        :plot_hint_subtitle = "over 2007-01-01 - 2007-05-31, Region 180W, 90S, 180E, 90N " ;
data:

 OMAERUVd_003_FinalAerosolAbsOpticalDepth500 = _, _, _, _, _, _, _, _, _, _,
    _, 0.005732692, 0.006581111, 0.007075, 0.009131111, 0.004580555,
    0.005465476, 0.007679146, 0.009428572, 0.01065788, 0.01075311,
    0.01020044, 0.01059343, 0.01057464, 0.01093628, 0.01054243, 0.01040399,
    0.01024107, 0.010555, 0.01058991, 0.01082234, 0.01120079, 0.01109179,
    0.01098205, 0.01090842, 0.01067376, 0.01084355, 0.0105546, 0.01102721,
    0.0108445, 0.01062187, 0.01086002, 0.01097366, 0.01089651, 0.0108049,
    0.0111255, 0.01132336, 0.01183876, 0.01190265, 0.01238493, 0.01284299,
    0.01273277, 0.01274212, 0.01318873, 0.0133806, 0.01266411, 0.0123679,
    0.01223416, 0.0122082, 0.01239032, 0.01283799, 0.01264289, 0.01335857,
    0.01406726, 0.0136835, 0.01354076, 0.01346605, 0.01407613, 0.01449858,
    0.01540472, 0.01636874, 0.01727555, 0.01697236, 0.01710043, 0.01886979,
    0.02071303, 0.0209736, 0.02122237, 0.02191506, 0.02317924, 0.02311635,
    0.02437284, 0.02510679, 0.02756837, 0.02940871, 0.03088564, 0.03095269,
    0.03290334, 0.03656573, 0.04043462, 0.02227949, 0.0241449, 0.0256703,
    0.02667642, 0.02811306, 0.02749476, 0.02779504, 0.02673381, 0.02709048,
    0.02630195, 0.02669799, 0.02745636, 0.02823166, 0.0287596, 0.02966023,
    0.03021878, 0.02934904, 0.02881913, 0.02977417, 0.0290994, 0.02990918,
    0.02926073, 0.02920911, 0.02991091, 0.03026013, 0.03118533, 0.03071805,
    0.03067967, 0.03001351, 0.03018758, 0.02917851, 0.02880954, 0.02710553,
    0.02733052, 0.02530651, 0.02425399, 0.02319269, 0.02246948, 0.02213282,
    0.02045375, 0.0192234, 0.01820018, 0.0165542, 0.0151861, 0.01542374,
    0.01480468, 0.01349664, 0.01279164, 0.01236739, 0.01189257, 0.01247538,
    0.01188147, 0.01306759, 0.01346336, 0.01303782, 0.0130661, 0.01388488,
    0.01337894, 0.0126784, 0.0114906, 0.01030282, 0.008109493, 0.008321685,
    0.008804344, 0.009125766, 0.007295664, 0.008229486, 0.01352808,
    0.02181816, 0.02002032, 0.01834002, 0.01460644, 0.01919092, 0.02036057,
    0.01825572, 0.02255302, 0.02398033, 0.04331125, 0.1132933, 0.007104762,
    0, _, _, _, _, _, _, _, _, _ ;

 lat = -89.5, -88.5, -87.5, -86.5, -85.5, -84.5, -83.5, -82.5, -81.5, -80.5,
    -79.5, -78.5, -77.5, -76.5, -75.5, -74.5, -73.5, -72.5, -71.5, -70.5,
    -69.5, -68.5, -67.5, -66.5, -65.5, -64.5, -63.5, -62.5, -61.5, -60.5,
    -59.5, -58.5, -57.5, -56.5, -55.5, -54.5, -53.5, -52.5, -51.5, -50.5,
    -49.5, -48.5, -47.5, -46.5, -45.5, -44.5, -43.5, -42.5, -41.5, -40.5,
    -39.5, -38.5, -37.5, -36.5, -35.5, -34.5, -33.5, -32.5, -31.5, -30.5,
    -29.5, -28.5, -27.5, -26.5, -25.5, -24.5, -23.5, -22.5, -21.5, -20.5,
    -19.5, -18.5, -17.5, -16.5, -15.5, -14.5, -13.5, -12.5, -11.5, -10.5,
    -9.5, -8.5, -7.5, -6.5, -5.5, -4.5, -3.5, -2.5, -1.5, -0.5, 0.5, 1.5,
    2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5, 11.5, 12.5, 13.5, 14.5,
    15.5, 16.5, 17.5, 18.5, 19.5, 20.5, 21.5, 22.5, 23.5, 24.5, 25.5, 26.5,
    27.5, 28.5, 29.5, 30.5, 31.5, 32.5, 33.5, 34.5, 35.5, 36.5, 37.5, 38.5,
    39.5, 40.5, 41.5, 42.5, 43.5, 44.5, 45.5, 46.5, 47.5, 48.5, 49.5, 50.5,
    51.5, 52.5, 53.5, 54.5, 55.5, 56.5, 57.5, 58.5, 59.5, 60.5, 61.5, 62.5,
    63.5, 64.5, 65.5, 66.5, 67.5, 68.5, 69.5, 70.5, 71.5, 72.5, 73.5, 74.5,
    75.5, 76.5, 77.5, 78.5, 79.5, 80.5, 81.5, 82.5, 83.5, 84.5, 85.5, 86.5,
    87.5, 88.5, 89.5 ;

 time = 1174089600 ;
}
"""
        cdl_file = os.path.join(self.dir, "data.cdl")
        handle = open(cdl_file, 'w')
        handle.write(cdl)
        handle.close()

        # run ncgen
        nc_file = os.path.join(self.dir, "data.nc")
        netcdf.ncgen(cdl_file, nc_file)

        self.assertEqual(netcdf.get_attribute(
            nc_file, "units", "OMAERUVd_003_FinalAerosolAbsOpticalDepth500"), "1", "Got out units")
        self.assertEqual(
            netcdf.get_attribute(nc_file, "NCO"), "4.4.4", "Got out NCO global attribute")

        try:
            netcdf.get_attribute(nc_file, "FAKE")
            self.fail("An invalid attribute should throw an error")
        except netcdf.NetCDFError:
            # nothing to do. This is correct.
            pass

if __name__ == "__main__":
    unittest.main()
