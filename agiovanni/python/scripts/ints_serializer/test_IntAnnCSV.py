
''' The URL is:
https://dev.gesdisc.eosdis.nasa.gov/giovanni/daac-bin/serializer.pl?SESSION=EEC22AFA-7BAB-11E7-BF44-045BF1999D63/10F083E2-7BAC-11E7-876F-CC5CF1999D63/10F326B0-7BAC-11E7-876F-CC5CF1999D63"

which turns out to be:
serialize_ints.py EEC22AFA-7BAB-11E7-BF44-045BF1999D63/10F083E2-7BAC-11E7-876F-CC5CF1999D63/10F326B0-7BAC-11E7-876F-CC5CF1999D63

looks for mfst.combine+sInTs+*.xml

nc file is about 25,000 bytes but the .cdl file is only 3K

since the data is put into python object and extracted straight from there...In the test we need to start from
the .nc file


'''

__author__ = 'Richard Strub <richard.f.strub@nasa.gov>'

import unittest
import os
import subprocess
import tempfile
import shutil
import re
import subprocess

from agiovanni import nco
from agiovanni import netcdf


import agiovanni.bbox as bb
from agiovanni import ScrubbingFramework


def createMyExe():
    '''
    In this case ncdump. Notice how we need to create myncdump to accomodate the arguments
    that are automatically passed to the script
    '''
    exe_file = os.path.join(os.environ['TMPDIR'], 'myncdump.csh')
    exe_fh = open(exe_file, 'w')
    exe_fh.write("""#!/bin/csh
        set file = $4
        ncdump -h $file | grep  lat_bnds
        """ )
    exe_fh.close()
    os.chmod(exe_file, 0o775)
    return exe_file


def runcmd(cmd):

    scmd = cmd.split(' ')
    p = subprocess.Popen(scmd, stdout=subprocess.PIPE)
    out = p.communicate()[0]
    return p.returncode


class RegressionTest(unittest.TestCase):

    def setUp(self):
        self.dir = tempfile.mkdtemp()
        

        cdl = """netcdf g4.ints.TRMM_3B43_7_precipitation.20140101-20161231.MONTH_01.180W_50S_180E_50N {
dimensions:
	time = UNLIMITED ; // (3 currently)
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	int datayear(time) ;
		datayear:long_name = "Data year" ;
	float TRMM_3B43_7_precipitation(time) ;
		TRMM_3B43_7_precipitation:_FillValue = -9999.9f ;
		TRMM_3B43_7_precipitation:long_name = "Precipitation Rate" ;
		TRMM_3B43_7_precipitation:product_short_name = "TRMM_3B43" ;
		TRMM_3B43_7_precipitation:product_version = "7" ;
		TRMM_3B43_7_precipitation:quantity_type = "Precipitation" ;
		TRMM_3B43_7_precipitation:standard_name = "precipitation" ;
		TRMM_3B43_7_precipitation:units = "mm/hr" ;
		TRMM_3B43_7_precipitation:cell_methods = "lat, lon: mean" ;
		TRMM_3B43_7_precipitation:group_type = "MONTH" ;
		TRMM_3B43_7_precipitation:group_value = "January" ;
		TRMM_3B43_7_precipitation:coordinates = "time" ;
		TRMM_3B43_7_precipitation:plot_hint_legend_label = "January" ;
	double lat_bnds(latv) ;
		lat_bnds:units = "degrees_north" ;
		lat_bnds:cell_methods = "lat: mean" ;
	double lon_bnds(lonv) ;
		lon_bnds:units = "degrees_east" ;
		lon_bnds:cell_methods = "lon: mean" ;
	int time(time) ;
		time:long_name = "time" ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
		time:bounds = "time_bnds" ;
	int time_bnds(time, nv) ;
		time_bnds:units = "seconds since 1970-01-01 00:00:00" ;

// global attributes:
		:nco_openmp_thread_number = 1 ;
		:Conventions = "CF-1.4" ;
		:temporal_resolution = "monthly" ;
		:start_time = "2014-01-01T00:00:00Z" ;
		:end_time = "2016-01-31T23:59:59Z" ;
		:userstartdate = "2014-01-01T00:00:00Z" ;
		:userenddate = "2016-12-31T23:59:59Z" ;
		:title = "Interannual time series Precipitation Rate monthly 0.25 deg. [TRMM TRMM_3B43 v7] mm/hr over 2014-Jan - 2016-Jan" ;
		:plot_hint_title = "Interannual time series Precipitation Rate monthly 0.25" ;
		:plot_hint_subtitle = "deg. [TRMM TRMM_3B43 v7] mm/hr over 2014-Jan - 2016-Jan" ;
		:plot_hint_time_axis_values = "1388534400,1420070400,1451606400,1483228800" ;
		:plot_hint_time_axis_labels = "2014,2015,2016,2017" ;
		:plot_hint_time_axis_minor = "1396310400,1404172800,1412121600,1427846400,1435708800,1443657600,1459468800,1467331200,1475280000" ;
		:history = "Mon Aug  7 20:08:11 2017: ncatted -a plot_hint_time_axis_values,global,c,c,1388534400,1420070400,1451606400,1483228800 -a plot_hint_time_axis_labels,global,c,c,2014,2015,2016,2017 -a plot_hint_time_axis_minor,global,c,c,1396310400,1404172800,1412121600,1427846400,1435708800,1443657600,1459468800,1467331200,1475280000 /var/giovanni/session/EEC22AFA-7BAB-11E7-BF44-045BF1999D63/10F083E2-7BAC-11E7-876F-CC5CF1999D63/10F326B0-7BAC-11E7-876F-CC5CF1999D63/g4.ints.TRMM_3B43_7_precipitation.20140101-20161231.MONTH_01.180W_50S_180E_50N.nc" ;
data:

 datayear = 2014, 2015, 2016 ;

 TRMM_3B43_7_precipitation = 0.1226119, 0.121721, 0.1265258 ;

 lat_bnds = -0.125, 0.125000000000007 ;

 lon_bnds = -0.125, 0.125 ;

 time = 1388534400, 1420070400, 1451606400 ;

 time_bnds =
  1388534400, 1391212799,
  1420070400, 1422748799,
  1451606400, 1454284799 ;
}"""
    
        cdl_file = os.path.join(self.dir, "ints.cdl")
        handle = open(cdl_file, 'w')
        handle.write(cdl)
        handle.close()

        # run ncgen
        nc_file = os.path.join(self.dir, "ints.MONTH_01.nc")
        netcdf.ncgen(cdl_file, nc_file)
        self.infile = nc_file

        xml_mfst = "<manifest><fileList><file>" + nc_file + "</file></fileList></manifest>"

        self.xml_mfst_file = os.path.join(self.dir, "mfst.combine+sInTs.MONTH_01.xml")
        handle = open(self.xml_mfst_file, 'w')
        handle.write(xml_mfst)
        handle.close()
 
        input_file = """<input>
<referer>https://dev.gesdisc.eosdis.nasa.gov/giovanni/</referer><query>session=EEC22AFA-7BAB-11E7-BF44-045BF1999D63&amp;service=InTs&amp;starttime=2014-01-01T00:00:00Z&amp;endtime=2016-12-31T23:59:59Z&amp;months=01&amp;data=TRMM_3B43_7_precipitation&amp;portal=GIOVANNI&amp;format=json</query><title>Time Series, Seasonal</title><description>Seasonal (inter annual) time series from 2014 to 2016 for Jan</description><result id="10F326B0-7BAC-11E7-876F-CC5CF1999D63"><dir>/var/giovanni/session/EEC22AFA-7BAB-11E7-BF44-045BF1999D63/10F083E2-7BAC-11E7-876F-CC5CF1999D63/10F326B0-7BAC-11E7-876F-CC5CF1999D63/</dir></result><data>TRMM_3B43_7_precipitation</data><endtime>2016-12-31T23:59:59Z</endtime><months>01</months><portal>GIOVANNI</portal><service>InTs</service><session>EEC22AFA-7BAB-11E7-BF44-045BF1999D63</session><starttime>2014-01-01T00:00:00Z</starttime>
</input>"""


        self.input_file = os.path.join(self.dir, "input.xml")
        handle = open(self.input_file, 'w')
        handle.write(input_file)
        handle.close()

    def testRunThroughCombinedAscii(self):


        myCmd = 'serialize_ints.py ' + self.dir
        status = runcmd(myCmd)

        expected_bbox = """Title:,"Interannual time series Precipitation Rate monthly 0.25 deg. [TRMM TRMM_3B43 v7] mm/hr over 2014-Jan - 2016-Jan"
User Start Date:,2014-01-01T00:00:00Z
User End Date:,2016-12-31T23:59:59Z
URL to Reproduce Results:,"https://dev.gesdisc.eosdis.nasa.gov/giovanni/#service=InTs&starttime=2014-01-01T00%3A00%3A00Z&endtime=2016-12-31T23%3A59%3A59Z&months=01&data=TRMM_3B43_7_precipitation&portal=GIOVANNI&format=json"
Fill Value:,-9999.9
Units:,mm/hr
Variable Name:,TRMM_3B43_7_precipitation

TIME,MONTH_01
2014,0.122612
2015,0.121721
2016,0.126526
"""
        expected_file = os.path.join(self.dir, "csv.expected")
        handle = open(expected_file, 'w')
        handle.write(expected_bbox)
        handle.close()

        status = runcmd("diff " + expected_file + " " + os.path.join(self.dir, "ints.MONTH_01.csv"))
        self.assertEqual(status, 0, "Combined ASCII output of interannual time series with bbox")

        #self.cleanup()
        #os.remove(self.xml_mfst_file)


if __name__ == "__main__":
    unittest.main()

