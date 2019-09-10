'''
Created on Jul 9, 2015
Test zonal_mean.py
@author: csmit
'''

import shutil
import tempfile
import unittest
import os
import StringIO

import agiovanni.netcdf as nc
import serialize_zonal_mean as zm


class Test(unittest.TestCase):

    """
    Tests serializer_zonal_mean
    """

    def setUp(self):
        self.dir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.dir)

    def runTest(self, cdl, input_XML, output_csv):
        # write input.xml
        input_file = os.path.join(self.dir, "input.xml")
        handle = open(input_file, 'w')
        handle.write(input_XML)
        handle.close()

        # create the input netcdf file
        cdl_file = os.path.join(self.dir, "data.cdl")
        handle = open(cdl_file, 'w')
        handle.write(cdl)
        handle.close()

        nc_file = os.path.join(self.dir, "data.nc")
        nc.ncgen(cdl_file, nc_file)

        # call the serializer
        io = StringIO.StringIO()
        zm.main([input_file, nc_file, self.dir], io)

        # make sure the csv was created
        csv_file = io.getvalue()
        self.assertTrue(
            os.path.exists(csv_file), "csv file exists: %s" % csv_file)

        # compare the values
        handle = open(csv_file)
        test_csv = handle.read()
        handle.close()

        self.assertEqual(output_csv, test_csv, "CSV is correct")

        # run it again. This time the code to should pick up on the file that is
        # already there.
        io = StringIO.StringIO()
        zm.main([input_file, nc_file, self.dir], io)

        # make sure we got the csv file out
        csv_file = io.getvalue()
        self.assertTrue(
            os.path.exists(csv_file), "csv file exists: %s" % csv_file)

        # compare the values
        handle = open(csv_file)
        test_csv = handle.read()
        handle.close()

        self.assertEqual(output_csv, test_csv, "CSV is correct")

    def testNoFill(self):
        '''
        Test the case where there are no fill values in the variable data.
        '''
        input_XML = """<input>
    <referer>http://giovanni.gsfc.nasa.gov/giovanni/</referer>
    <query>session=DC84685E-72B5-11E5-9728-8156E138E3F4&amp;service=ZnMn&amp;starttime=2007-01-01T00:00:00Z&amp;endtime=2007-05-31T23:59:59Z&amp;bbox=-50.5078,2.7539,18.3985,35.0977&amp;data=OMAERUVd_003_FinalAerosolAbsOpticalDepth500&amp;portal=GIOVANNI&amp;format=json</query>
    <title>Zonal Mean</title>
    <description>Zonal mean plot, averaged values are plotted over latitude zones from 2007-01-01T00:00:00Z to 2007-05-31T23:59:59Z over -50.5078,2.7539,18.3985,35.0977</description>
    <result id="F8D47350-72B5-11E5-9903-D656E138E3F4">
        <dir>/var/giovanni/session/DC84685E-72B5-11E5-9728-8156E138E3F4/F8D0A6B2-72B5-11E5-9903-D656E138E3F4/F8D47350-72B5-11E5-9903-D656E138E3F4/</dir>
    </result>
    <bbox>-50.5078,2.7539,18.3985,35.0977</bbox>
    <data>OMAERUVd_003_FinalAerosolAbsOpticalDepth500</data>
    <endtime>2007-05-31T23:59:59Z</endtime>
    <portal>GIOVANNI</portal>
    <service>ZnMn</service>
    <session>DC84685E-72B5-11E5-9728-8156E138E3F4</session>
    <starttime>2007-01-01T00:00:00Z</starttime>
</input>
"""
        cdl = """netcdf g4.dimensionAveraged.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20070101-20070531.50W_2N_18E_35N {
dimensions:
    lat = 32 ;
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

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2007-01-01T00:00:00Z" ;
        :end_time = "2007-05-31T23:59:59Z" ;
        :history = "Wed Oct 14 20:56:06 2015: ncatted -a valid_range,,d,, -O -o dimensionAveraged.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20070101-20070531.50W_2N_18E_35N.nc dimensionAveraged.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20070101-20070531.50W_2N_18E_35N.nc\n",
            "Wed Oct 14 20:56:06 2015: ncks -x -v lon,time -O dimensionAveraged.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20070101-20070531.50W_2N_18E_35N.nc dimensionAveraged.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20070101-20070531.50W_2N_18E_35N.nc\n",
            "Wed Oct 14 20:56:06 2015: ncks -O -d lat,2.7539,35.0977 -d lon,-50.5078,18.3985 dimensionAveraged.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20070101-20070531.50W_2N_18E_35N.nc dimensionAveraged.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20070101-20070531.50W_2N_18E_35N.nc.subset\n",
            "Wed Oct 14 20:56:06 2015: ncatted -O -a title,global,o,c,OMAERUVd_003_FinalAerosolAbsOpticalDepth500 Averaged over 2007-01-01 to 2007-05-31 dimensionAveraged.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20070101-20070531.50W_2N_18E_35N.nc\n",
            "Wed Oct 14 20:56:06 2015: ncks -x -v time -o dimensionAveraged.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20070101-20070531.50W_2N_18E_35N.nc -O dimensionAveraged.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20070101-20070531.50W_2N_18E_35N.nc\n",
            "Wed Oct 14 20:56:06 2015: ncwa -o dimensionAveraged.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20070101-20070531.50W_2N_18E_35N.nc -a time -O dimensionAveraged.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20070101-20070531.50W_2N_18E_35N.nc\n",
            "Wed Oct 14 20:56:06 2015: ncra -D 2 -H -O -o dimensionAveraged.OMAERUVd_003_FinalAerosolAbsOpticalDepth500.20070101-20070531.50W_2N_18E_35N.nc -d lat,2.753900,35.097700 -d lon,-50.507800,18.398500" ;
        :NCO = "4.4.4" ;
        :title = "Zonal Mean of Aerosol Absorption Optical Depth 500 nm daily 1 deg. [OMI OMAERUVd v003] over 2007-01-01 - 2007-05-31, Region 50.5078W, 2.7539N, 18.3985E, 35.0977N " ;
        :userstartdate = "2007-01-01T00:00:00Z" ;
        :userenddate = "2007-05-31T23:59:59Z" ;
        :plot_hint_title = "Zonal Mean of Aerosol Absorption Optical Depth 500 nm daily 1 deg. [OMI OMAERUVd v003]" ;
        :plot_hint_subtitle = "over 2007-01-01 - 2007-05-31, Region 50.5078W, 2.7539N, 18.3985E, 35.0977N " ;
data:

 OMAERUVd_003_FinalAerosolAbsOpticalDepth500 = 0.07875772, 0.07790562,
    0.07439012, 0.0731443, 0.06949405, 0.06664108, 0.06070616, 0.05572104,
    0.05335009, 0.05236242, 0.05103108, 0.05009672, 0.0499377, 0.04556777,
    0.03981041, 0.03516639, 0.03061524, 0.0273269, 0.02419658, 0.02213125,
    0.02208364, 0.02230738, 0.02069894, 0.02030823, 0.0215175, 0.02088076,
    0.02193094, 0.02168096, 0.02327107, 0.02239761, 0.02539606, 0.02349293 ;

 lat = 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5, 11.5, 12.5, 13.5, 14.5, 15.5,
    16.5, 17.5, 18.5, 19.5, 20.5, 21.5, 22.5, 23.5, 24.5, 25.5, 26.5, 27.5,
    28.5, 29.5, 30.5, 31.5, 32.5, 33.5, 34.5 ;
}
"""

        output_csv = """Title:,"Zonal Mean of Aerosol Absorption Optical Depth 500 nm daily 1 deg. [OMI OMAERUVd v003] over 2007-01-01 - 2007-05-31, Region 50.5078W, 2.7539N, 18.3985E, 35.0977N"
User Start Date:,2007-01-01T00:00:00Z
User End Date:,2007-05-31T23:59:59Z
Bounding Box:,"-50.5078,2.7539,18.3985,35.0977"
URL to Reproduce Results:,"http://giovanni.gsfc.nasa.gov/giovanni/#service=ZnMn&starttime=2007-01-01T00%3A00%3A00Z&endtime=2007-05-31T23%3A59%3A59Z&bbox=-50.5078%2C2.7539%2C18.3985%2C35.0977&data=OMAERUVd_003_FinalAerosolAbsOpticalDepth500&portal=GIOVANNI&format=json"
Fill Value:,-1.26765e+30

latitude (degrees north),OMAERUVd_003_FinalAerosolAbsOpticalDepth500
3.5,0.0787577
4.5,0.0779056
5.5,0.0743901
6.5,0.0731443
7.5,0.0694941
8.5,0.0666411
9.5,0.0607062
10.5,0.055721
11.5,0.0533501
12.5,0.0523624
13.5,0.0510311
14.5,0.0500967
15.5,0.0499377
16.5,0.0455678
17.5,0.0398104
18.5,0.0351664
19.5,0.0306152
20.5,0.0273269
21.5,0.0241966
22.5,0.0221312
23.5,0.0220836
24.5,0.0223074
25.5,0.0206989
26.5,0.0203082
27.5,0.0215175
28.5,0.0208808
29.5,0.0219309
30.5,0.021681
31.5,0.0232711
32.5,0.0223976
33.5,0.0253961
34.5,0.0234929
"""
        self.runTest(input_XML=input_XML, cdl=cdl, output_csv=output_csv)

    def testBasic(self):
        '''
        Do a simple test.
        '''
        input_XML = """
<input>
    <referer>http://dev.gesdisc.eosdis.nasa.gov/~csmit/giovanni/</referer>
    <query>session=70F398A6-266D-11E5-9ECD-CCDDB2DD2DA6&amp;service=ZnMn&amp;starttime=2007-01-01T00:00:00Z&amp;endtime=2007-05-31T23:59:59Z&amp;bbox=-180,-90,180,90&amp;data=OMAERUVd_003_FinalAerosolAbsOpticalDepth500&amp;portal=GIOVANNI&amp;format=json</query>
    <title>Zonal Mean</title>
    <description>Zonal mean plot, averaged values are plotted over latitude zones from 2007-01-01T00:00:00Z to 2007-05-31T23:59:59Z over -180,-90,180,90</description>
    <result id="73F73F4E-266D-11E5-A115-08DEB2DD2DA6">
        <dir>/var/giovanni/session/70F398A6-266D-11E5-9ECD-CCDDB2DD2DA6/73F72B3A-266D-11E5-A115-08DEB2DD2DA6/73F73F4E-266D-11E5-A115-08DEB2DD2DA6/</dir>
    </result>
    <bbox>-180,-90,180,90</bbox>
    <data>OMAERUVd_003_FinalAerosolAbsOpticalDepth500</data>
    <endtime>2007-05-31T23:59:59Z</endtime>
    <portal>GIOVANNI</portal>
    <service>ZnMn</service>
    <session>70F398A6-266D-11E5-9ECD-CCDDB2DD2DA6</session>
    <starttime>2007-01-01T00:00:00Z</starttime>
</input>
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
        output_csv = """Title:,"Zonal Mean of Aerosol Absorption Optical Depth 500 nm daily 1 deg. [OMI OMAERUVd v003] over 2007-01-01 - 2007-05-31, Region 180W, 90S, 180E, 90N"
User Start Date:,2007-01-01T00:00:00Z
User End Date:,2007-05-31T23:59:59Z
Bounding Box:,"-180,-90,180,90"
URL to Reproduce Results:,"http://dev.gesdisc.eosdis.nasa.gov/~csmit/giovanni/#service=ZnMn&starttime=2007-01-01T00%3A00%3A00Z&endtime=2007-05-31T23%3A59%3A59Z&bbox=-180%2C-90%2C180%2C90&data=OMAERUVd_003_FinalAerosolAbsOpticalDepth500&portal=GIOVANNI&format=json"
Fill Value:,-1.26765e+30

latitude (degrees north),OMAERUVd_003_FinalAerosolAbsOpticalDepth500
-89.5,-1.26765e+30
-88.5,-1.26765e+30
-87.5,-1.26765e+30
-86.5,-1.26765e+30
-85.5,-1.26765e+30
-84.5,-1.26765e+30
-83.5,-1.26765e+30
-82.5,-1.26765e+30
-81.5,-1.26765e+30
-80.5,-1.26765e+30
-79.5,-1.26765e+30
-78.5,0.00573269
-77.5,0.00658111
-76.5,0.007075
-75.5,0.00913111
-74.5,0.00458056
-73.5,0.00546548
-72.5,0.00767915
-71.5,0.00942857
-70.5,0.0106579
-69.5,0.0107531
-68.5,0.0102004
-67.5,0.0105934
-66.5,0.0105746
-65.5,0.0109363
-64.5,0.0105424
-63.5,0.010404
-62.5,0.0102411
-61.5,0.010555
-60.5,0.0105899
-59.5,0.0108223
-58.5,0.0112008
-57.5,0.0110918
-56.5,0.010982
-55.5,0.0109084
-54.5,0.0106738
-53.5,0.0108435
-52.5,0.0105546
-51.5,0.0110272
-50.5,0.0108445
-49.5,0.0106219
-48.5,0.01086
-47.5,0.0109737
-46.5,0.0108965
-45.5,0.0108049
-44.5,0.0111255
-43.5,0.0113234
-42.5,0.0118388
-41.5,0.0119026
-40.5,0.0123849
-39.5,0.012843
-38.5,0.0127328
-37.5,0.0127421
-36.5,0.0131887
-35.5,0.0133806
-34.5,0.0126641
-33.5,0.0123679
-32.5,0.0122342
-31.5,0.0122082
-30.5,0.0123903
-29.5,0.012838
-28.5,0.0126429
-27.5,0.0133586
-26.5,0.0140673
-25.5,0.0136835
-24.5,0.0135408
-23.5,0.013466
-22.5,0.0140761
-21.5,0.0144986
-20.5,0.0154047
-19.5,0.0163687
-18.5,0.0172755
-17.5,0.0169724
-16.5,0.0171004
-15.5,0.0188698
-14.5,0.020713
-13.5,0.0209736
-12.5,0.0212224
-11.5,0.0219151
-10.5,0.0231792
-9.5,0.0231164
-8.5,0.0243728
-7.5,0.0251068
-6.5,0.0275684
-5.5,0.0294087
-4.5,0.0308856
-3.5,0.0309527
-2.5,0.0329033
-1.5,0.0365657
-0.5,0.0404346
0.5,0.0222795
1.5,0.0241449
2.5,0.0256703
3.5,0.0266764
4.5,0.0281131
5.5,0.0274948
6.5,0.027795
7.5,0.0267338
8.5,0.0270905
9.5,0.026302
10.5,0.026698
11.5,0.0274564
12.5,0.0282317
13.5,0.0287596
14.5,0.0296602
15.5,0.0302188
16.5,0.029349
17.5,0.0288191
18.5,0.0297742
19.5,0.0290994
20.5,0.0299092
21.5,0.0292607
22.5,0.0292091
23.5,0.0299109
24.5,0.0302601
25.5,0.0311853
26.5,0.0307181
27.5,0.0306797
28.5,0.0300135
29.5,0.0301876
30.5,0.0291785
31.5,0.0288095
32.5,0.0271055
33.5,0.0273305
34.5,0.0253065
35.5,0.024254
36.5,0.0231927
37.5,0.0224695
38.5,0.0221328
39.5,0.0204537
40.5,0.0192234
41.5,0.0182002
42.5,0.0165542
43.5,0.0151861
44.5,0.0154237
45.5,0.0148047
46.5,0.0134966
47.5,0.0127916
48.5,0.0123674
49.5,0.0118926
50.5,0.0124754
51.5,0.0118815
52.5,0.0130676
53.5,0.0134634
54.5,0.0130378
55.5,0.0130661
56.5,0.0138849
57.5,0.0133789
58.5,0.0126784
59.5,0.0114906
60.5,0.0103028
61.5,0.00810949
62.5,0.00832168
63.5,0.00880434
64.5,0.00912577
65.5,0.00729566
66.5,0.00822949
67.5,0.0135281
68.5,0.0218182
69.5,0.0200203
70.5,0.01834
71.5,0.0146064
72.5,0.0191909
73.5,0.0203606
74.5,0.0182557
75.5,0.022553
76.5,0.0239803
77.5,0.0433112
78.5,0.113293
79.5,0.00710476
80.5,0.0
81.5,-1.26765e+30
82.5,-1.26765e+30
83.5,-1.26765e+30
84.5,-1.26765e+30
85.5,-1.26765e+30
86.5,-1.26765e+30
87.5,-1.26765e+30
88.5,-1.26765e+30
89.5,-1.26765e+30
"""
        self.runTest(input_XML=input_XML, cdl=cdl, output_csv=output_csv)

    def testNoBoundingBox(self):
        '''
        Simple test but with no bbox in input.xml, assume default global bbox
        '''
        input_XML = """
<input>
    <referer>http://dev.gesdisc.eosdis.nasa.gov/~csmit/giovanni/</referer>
    <query>session=70F398A6-266D-11E5-9ECD-CCDDB2DD2DA6&amp;service=ZnMn&amp;starttime=2007-01-01T00:00:00Z&amp;endtime=2007-05-31T23:59:59Z&amp;bbox=-180,-90,180,90&amp;data=OMAERUVd_003_FinalAerosolAbsOpticalDepth500&amp;portal=GIOVANNI&amp;format=json</query>
    <title>Zonal Mean</title>
    <description>Zonal mean plot, averaged values are plotted over latitude zones from 2007-01-01T00:00:00Z to 2007-05-31T23:59:59Z over -180,-90,180,90</description>
    <result id="73F73F4E-266D-11E5-A115-08DEB2DD2DA6">
        <dir>/var/giovanni/session/70F398A6-266D-11E5-9ECD-CCDDB2DD2DA6/73F72B3A-266D-11E5-A115-08DEB2DD2DA6/73F73F4E-266D-11E5-A115-08DEB2DD2DA6/</dir>
    </result>
    <data>OMAERUVd_003_FinalAerosolAbsOpticalDepth500</data>
    <endtime>2007-05-31T23:59:59Z</endtime>
    <portal>GIOVANNI</portal>
    <service>ZnMn</service>
    <session>70F398A6-266D-11E5-9ECD-CCDDB2DD2DA6</session>
    <starttime>2007-01-01T00:00:00Z</starttime>
</input>
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
        output_csv = """Title:,"Zonal Mean of Aerosol Absorption Optical Depth 500 nm daily 1 deg. [OMI OMAERUVd v003] over 2007-01-01 - 2007-05-31, Region 180W, 90S, 180E, 90N"
User Start Date:,2007-01-01T00:00:00Z
User End Date:,2007-05-31T23:59:59Z
URL to Reproduce Results:,"http://dev.gesdisc.eosdis.nasa.gov/~csmit/giovanni/#service=ZnMn&starttime=2007-01-01T00%3A00%3A00Z&endtime=2007-05-31T23%3A59%3A59Z&bbox=-180%2C-90%2C180%2C90&data=OMAERUVd_003_FinalAerosolAbsOpticalDepth500&portal=GIOVANNI&format=json"
Fill Value:,-1.26765e+30

latitude (degrees north),OMAERUVd_003_FinalAerosolAbsOpticalDepth500
-89.5,-1.26765e+30
-88.5,-1.26765e+30
-87.5,-1.26765e+30
-86.5,-1.26765e+30
-85.5,-1.26765e+30
-84.5,-1.26765e+30
-83.5,-1.26765e+30
-82.5,-1.26765e+30
-81.5,-1.26765e+30
-80.5,-1.26765e+30
-79.5,-1.26765e+30
-78.5,0.00573269
-77.5,0.00658111
-76.5,0.007075
-75.5,0.00913111
-74.5,0.00458056
-73.5,0.00546548
-72.5,0.00767915
-71.5,0.00942857
-70.5,0.0106579
-69.5,0.0107531
-68.5,0.0102004
-67.5,0.0105934
-66.5,0.0105746
-65.5,0.0109363
-64.5,0.0105424
-63.5,0.010404
-62.5,0.0102411
-61.5,0.010555
-60.5,0.0105899
-59.5,0.0108223
-58.5,0.0112008
-57.5,0.0110918
-56.5,0.010982
-55.5,0.0109084
-54.5,0.0106738
-53.5,0.0108435
-52.5,0.0105546
-51.5,0.0110272
-50.5,0.0108445
-49.5,0.0106219
-48.5,0.01086
-47.5,0.0109737
-46.5,0.0108965
-45.5,0.0108049
-44.5,0.0111255
-43.5,0.0113234
-42.5,0.0118388
-41.5,0.0119026
-40.5,0.0123849
-39.5,0.012843
-38.5,0.0127328
-37.5,0.0127421
-36.5,0.0131887
-35.5,0.0133806
-34.5,0.0126641
-33.5,0.0123679
-32.5,0.0122342
-31.5,0.0122082
-30.5,0.0123903
-29.5,0.012838
-28.5,0.0126429
-27.5,0.0133586
-26.5,0.0140673
-25.5,0.0136835
-24.5,0.0135408
-23.5,0.013466
-22.5,0.0140761
-21.5,0.0144986
-20.5,0.0154047
-19.5,0.0163687
-18.5,0.0172755
-17.5,0.0169724
-16.5,0.0171004
-15.5,0.0188698
-14.5,0.020713
-13.5,0.0209736
-12.5,0.0212224
-11.5,0.0219151
-10.5,0.0231792
-9.5,0.0231164
-8.5,0.0243728
-7.5,0.0251068
-6.5,0.0275684
-5.5,0.0294087
-4.5,0.0308856
-3.5,0.0309527
-2.5,0.0329033
-1.5,0.0365657
-0.5,0.0404346
0.5,0.0222795
1.5,0.0241449
2.5,0.0256703
3.5,0.0266764
4.5,0.0281131
5.5,0.0274948
6.5,0.027795
7.5,0.0267338
8.5,0.0270905
9.5,0.026302
10.5,0.026698
11.5,0.0274564
12.5,0.0282317
13.5,0.0287596
14.5,0.0296602
15.5,0.0302188
16.5,0.029349
17.5,0.0288191
18.5,0.0297742
19.5,0.0290994
20.5,0.0299092
21.5,0.0292607
22.5,0.0292091
23.5,0.0299109
24.5,0.0302601
25.5,0.0311853
26.5,0.0307181
27.5,0.0306797
28.5,0.0300135
29.5,0.0301876
30.5,0.0291785
31.5,0.0288095
32.5,0.0271055
33.5,0.0273305
34.5,0.0253065
35.5,0.024254
36.5,0.0231927
37.5,0.0224695
38.5,0.0221328
39.5,0.0204537
40.5,0.0192234
41.5,0.0182002
42.5,0.0165542
43.5,0.0151861
44.5,0.0154237
45.5,0.0148047
46.5,0.0134966
47.5,0.0127916
48.5,0.0123674
49.5,0.0118926
50.5,0.0124754
51.5,0.0118815
52.5,0.0130676
53.5,0.0134634
54.5,0.0130378
55.5,0.0130661
56.5,0.0138849
57.5,0.0133789
58.5,0.0126784
59.5,0.0114906
60.5,0.0103028
61.5,0.00810949
62.5,0.00832168
63.5,0.00880434
64.5,0.00912577
65.5,0.00729566
66.5,0.00822949
67.5,0.0135281
68.5,0.0218182
69.5,0.0200203
70.5,0.01834
71.5,0.0146064
72.5,0.0191909
73.5,0.0203606
74.5,0.0182557
75.5,0.022553
76.5,0.0239803
77.5,0.0433112
78.5,0.113293
79.5,0.00710476
80.5,0.0
81.5,-1.26765e+30
82.5,-1.26765e+30
83.5,-1.26765e+30
84.5,-1.26765e+30
85.5,-1.26765e+30
86.5,-1.26765e+30
87.5,-1.26765e+30
88.5,-1.26765e+30
89.5,-1.26765e+30
"""
        self.runTest(input_XML=input_XML, cdl=cdl, output_csv=output_csv)


if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()
