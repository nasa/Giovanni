
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
        

        cdl = """netcdf g4.ints.M2IMNPANA_5_12_4_H.500hPa.19980101-20021231.SEASON_DJF.38E_32N_59E_40N {
dimensions:
	time = UNLIMITED ; // (5 currently)
	lev = 1 ;
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	int datayear(time) ;
		datayear:long_name = "Data year" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
	float M2IMNPANA_5_12_4_H(time, lev) ;
		M2IMNPANA_5_12_4_H:_FillValue = 1.e+15f ;
		M2IMNPANA_5_12_4_H:missing_value = 1.e+15f ;
		M2IMNPANA_5_12_4_H:fmissing_value = 1.e+15f ;
		M2IMNPANA_5_12_4_H:vmax = 1.e+15f ;
		M2IMNPANA_5_12_4_H:vmin = -1.e+15f ;
		M2IMNPANA_5_12_4_H:origname = "H" ;
		M2IMNPANA_5_12_4_H:fullnamepath = "/H" ;
		M2IMNPANA_5_12_4_H:standard_name = "geopotential_height" ;
		M2IMNPANA_5_12_4_H:quantity_type = "Geopotential" ;
		M2IMNPANA_5_12_4_H:product_short_name = "M2IMNPANA" ;
		M2IMNPANA_5_12_4_H:product_version = "5.12.4" ;
		M2IMNPANA_5_12_4_H:long_name = "Geopotential height" ;
		M2IMNPANA_5_12_4_H:units = "m" ;
		M2IMNPANA_5_12_4_H:cell_methods = "lat, lon: mean time: mean" ;
		M2IMNPANA_5_12_4_H:group_type = "SEASON" ;
		M2IMNPANA_5_12_4_H:group_value = "DJF" ;
		M2IMNPANA_5_12_4_H:coordinates = "time lev" ;
		M2IMNPANA_5_12_4_H:plot_hint_legend_label = "DJF" ;
		M2IMNPANA_5_12_4_H:z_slice = "500hPa" ;
		M2IMNPANA_5_12_4_H:z_slice_type = "pressure" ;
	double lat_bnds(time, latv) ;
		lat_bnds:units = "degrees_north" ;
		lat_bnds:cell_methods = "lat: mean" ;
	double lev(lev) ;
		lev:long_name = "vertical level" ;
		lev:positive = "down" ;
		lev:vmax = 1.e+15f ;
		lev:vmin = -1.e+15f ;
		lev:origname = "lev" ;
		lev:fullnamepath = "/lev" ;
		lev:standard_name = "lev" ;
		lev:units = "hPa" ;
	double lon_bnds(time, lonv) ;
		lon_bnds:units = "degrees_east" ;
		lon_bnds:cell_methods = "lon: mean" ;
	int time_bnds(time, nv) ;
		time_bnds:units = "seconds since 1970-01-01 00:00:00" ;
		time_bnds:cell_methods = "time: mean" ;

// global attributes:
		:Conventions = "CF-1.4" ;
		:temporal_resolution = "monthly" ;
		:nco_openmp_thread_number = 1 ;
		:start_time = "1997-12-01T00:00:00Z" ;
		:end_time = "2002-02-28T23:59:59Z" ;
		:userstartdate = "1998-01-01T00:00:00Z" ;
		:userenddate = "2002-12-31T23:59:59Z" ;
		:title = "Interannual time series Average Geopotential height monthly 0.5 x 0.625 deg. @500hPa [MERRA-2 Model M2IMNPANA v5.12.4] m for 1997-Dec - 2002-Feb, Region 38.6719E, 32.3438N, 59.7656E, 40.7813N" ;
		:plot_hint_title = "Interannual time series Average Geopotential height monthly 0.5 x 0.625 deg. @500hPa" ;
		:plot_hint_subtitle = "[MERRA-2 Model M2IMNPANA v5.12.4] m for 1997-Dec - 2002-Feb, Region 38.6719E, 32.3438N, 59.7656E, 40.7813N" ;
		:plot_hint_time_axis_values = "946684800,1104537600" ;
		:plot_hint_time_axis_labels = "2000,2005" ;
		:plot_hint_time_axis_minor = "883612800,915148800,978307200,1009843200" ;
		:history = "Fri Jul 13 16:31:15 2018: ncatted -a plot_hint_time_axis_values,global,c,c,946684800,1104537600 -a plot_hint_time_axis_labels,global,c,c,2000,2005 -a plot_hint_time_axis_minor,global,c,c,883612800,915148800,978307200,1009843200 /var/giovanni/session/4EDA6C06-86AD-11E8-A1E2-AD9512B0267B/BDED84F0-86B9-11E8-8B60-C9B211B0267B/BDEE363E-86B9-11E8-8B60-C9B211B0267B/g4.ints.M2IMNPANA_5_12_4_H.500hPa.19980101-20021231.SEASON_DJF.38E_32N_59E_40N.nc" ;
		:plot_hint_caption = "- Seasons with missing months are discarded.\n",
			"- DJF seasons are plotted against the year of the January and February data granules." ;
data:

 datayear = 1998, 1999, 2000, 2001, 2002 ;

 time = 880934400, 912470400, 944006400, 975628800, 1007164800 ;

 M2IMNPANA_5_12_4_H =
  5584.977,
  5647.564,
  5621.082,
  5615.685,
  5623.948 ;

 lat_bnds =
  36.1724829205357, 36.6724829205357,
  36.1724829205357, 36.6724829205357,
  36.1724829205357, 36.6724829205357,
  36.1724829205357, 36.6724829205357,
  36.1724829205357, 36.6724829205357 ;

 lev = 500 ;

 lon_bnds =
  48.75, 49.375,
  48.75, 49.375,
  48.75, 49.375,
  48.75, 49.375,
  48.75, 49.375 ;

 time_bnds =
  883612800, 886204799,
  915148800, 917740799,
  946684800, 949305599,
  978307200, 980899199,
  1009843200, 1012435199 ;
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
 
        input_file = """<input><referer>https://dev.gesdisc.eosdis.nasa.gov/~rstrub/giovanni/</referer><query>session=4EDA6C06-86AD-11E8-A1E2-AD9512B0267B&amp;service=InTs&amp;starttime=1998-01-01T00:00:00Z&amp;endtime=2002-12-31T23:59:59Z&amp;seasons=DJF&amp;bbox=38.6719,32.3438,59.7656,40.7813&amp;data=M2IMNPANA_5_12_4_H(z%3D500)&amp;variableFacets=dataFieldMeasurement%3AGeopotential%3B&amp;dataKeyword=MERRA-2&amp;portal=GIOVANNI&amp;format=json</query><title>Time Series, Seasonal</title><description>Seasonal (inter annual) time series from 1998 to 2002 for Dec-Jan-Feb(DJF) over 38.6719,32.3438,59.7656,40.7813</description><result id="2E00B95C-86BE-11E8-A253-000512B0267B"><dir>/var/giovanni/session/4EDA6C06-86AD-11E8-A1E2-AD9512B0267B/2DFE6A58-86BE-11E8-A253-000512B0267B/2E00B95C-86BE-11E8-A253-000512B0267B/</dir></result><bbox>38.6719,32.3438,59.7656,40.7813</bbox><data zValue="500">M2IMNPANA_5_12_4_H</data><dataKeyword>MERRA-2</dataKeyword><endtime>2002-12-31T23:59:59Z</endtime><portal>GIOVANNI</portal><seasons>DJF</seasons><service>InTs</service><session>4EDA6C06-86AD-11E8-A1E2-AD9512B0267B</session><starttime>1998-01-01T00:00:00Z</starttime><variableFacets>dataFieldMeasurement:Geopotential;</variableFacets></input>"""



        self.input_file = os.path.join(self.dir, "input.xml")
        handle = open(self.input_file, 'w')
        handle.write(input_file)
        handle.close()

    def testRunThroughCombinedAscii(self):


        myCmd = 'serialize_ints.py ' + self.dir
        status = runcmd(myCmd)

        expected_bbox="""Title:,"Interannual time series Average Geopotential height monthly 0.5 x 0.625 deg. @500hPa [MERRA-2 Model M2IMNPANA v5.12.4] m for 1997-Dec - 2002-Feb, Region 38.6719E, 32.3438N, 59.7656E, 40.7813N"
User Start Date:,1998-01-01T00:00:00Z
User End Date:,2002-12-31T23:59:59Z
Bounding Box:,"38.6719,32.3438,59.7656,40.7813"
URL to Reproduce Results:,"https://dev.gesdisc.eosdis.nasa.gov/~rstrub/giovanni/#service=InTs&starttime=1998-01-01T00%3A00%3A00Z&endtime=2002-12-31T23%3A59%3A59Z&seasons=DJF&bbox=38.6719%2C32.3438%2C59.7656%2C40.7813&data=M2IMNPANA_5_12_4_H%28z%3D500%29&variableFacets=dataFieldMeasurement%3AGeopotential%3B&dataKeyword=MERRA-2&portal=GIOVANNI&format=json"
Fill Value:,1e+15
Units:,m
Variable Name:,M2IMNPANA_5_12_4_H

TIME,MONTH_01
1998,5584.98
1999,5647.56
2000,5621.08
2001,5615.69
2002,5623.95
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

