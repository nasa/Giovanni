
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
        
        cdl = """netcdf g4.ints.NLDAS_MOS0125_M_002_evcwsfc.20090101-20161231.SEASON_JJA.88W_34N_77W_41N {
dimensions:
	time = UNLIMITED ; // (8 currently)
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	int datayear(time) ;
		datayear:long_name = "Data year" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
	float NLDAS_MOS0125_M_002_evcwsfc(time) ;
		NLDAS_MOS0125_M_002_evcwsfc:cell_methods = "time: mean lat, lon: mean" ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_param_name = "Canopy_water_evaporation" ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_param_short_name = "EVCW" ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_center_id = 7 ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_table_id = 130 ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_param_number = 200 ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_param_id = 1, 7, 130, 200 ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_product_definition_type = "Average" ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_level_type = 1 ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_VectorComponentFlag = "easterlyNortherlyRelative" ;
		NLDAS_MOS0125_M_002_evcwsfc:standard_name = "canopy_water_evaporation" ;
		NLDAS_MOS0125_M_002_evcwsfc:_FillValue = -9999.f ;
		NLDAS_MOS0125_M_002_evcwsfc:quantity_type = "Evaporation" ;
		NLDAS_MOS0125_M_002_evcwsfc:product_short_name = "NLDAS_MOS0125_M" ;
		NLDAS_MOS0125_M_002_evcwsfc:product_version = "002" ;
		NLDAS_MOS0125_M_002_evcwsfc:long_name = "Canopy water evaporation" ;
		NLDAS_MOS0125_M_002_evcwsfc:units = "W/m^2" ;
		NLDAS_MOS0125_M_002_evcwsfc:group_type = "SEASON" ;
		NLDAS_MOS0125_M_002_evcwsfc:group_value = "JJA" ;
		NLDAS_MOS0125_M_002_evcwsfc:coordinates = "time" ;
		NLDAS_MOS0125_M_002_evcwsfc:plot_hint_legend_label = "JJA" ;
	double lat_bnds(time, latv) ;
		lat_bnds:units = "degrees_north" ;
		lat_bnds:cell_methods = "lat: mean" ;
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
		:start_time = "2009-06-01T00:00:00Z" ;
		:end_time = "2016-08-31T23:59:59Z" ;
		:userstartdate = "2009-01-01T00:00:00Z" ;
		:userenddate = "2016-12-31T23:59:59Z" ;
		:title = "Interannual time series Canopy water evaporation monthly 0.125 deg. [NLDAS Model NLDAS_MOS0125_M v002] W/m^2 over 2009-Jun - 2016-Aug, Region 88.5937W, 34.5703N, 77.3437W, 41.6016N" ;
		:plot_hint_title = "Interannual time series Canopy water evaporation monthly 0.125 deg. [NLDAS Model" ;
		:plot_hint_subtitle = "NLDAS_MOS0125_M v002] W/m^2 over 2009-Jun - 2016-Aug, Region 88.5937W, 34.5703N, 77.3437W, 41.6016N" ;
		:plot_hint_time_axis_values = "1262304000,1420070400,1577836800" ;
		:plot_hint_time_axis_labels = "2010,2015,2020" ;
		:plot_hint_time_axis_minor = "1230768000,1293840000,1325376000,1356998400,1388534400,1451606400" ;
		:history = "Tue Aug  8 16:42:48 2017: ncatted -a plot_hint_time_axis_values,global,c,c,1262304000,1420070400,1577836800 -a plot_hint_time_axis_labels,global,c,c,2010,2015,2020 -a plot_hint_time_axis_minor,global,c,c,1230768000,1293840000,1325376000,1356998400,1388534400,1451606400 /var/giovanni/session/452EB79C-7C55-11E7-ABCA-C521F1999D63/56FD3C76-7C57-11E7-9260-D168F1999D63/56FF054C-7C57-11E7-9260-D168F1999D63/g4.ints.NLDAS_MOS0125_M_002_evcwsfc.20090101-20161231.SEASON_JJA.88W_34N_77W_41N.nc" ;
		:plot_hint_caption = "- Seasons with missing months are discarded.\n",
			"- DJF seasons are plotted against the year of the January and February data granules." ;
data:

 datayear = 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016 ;

 time = 1243814400, 1275350400, 1306886400, 1338508800, 1370044800, 
    1401580800, 1433116800, 1464739200 ;

 NLDAS_MOS0125_M_002_evcwsfc = -15.94302, -13.77004, -12.49541, -12.13854, 
    -15.9496, -14.06023, -14.56764, -13.81603 ;

 lat_bnds =
  38.0065727390533, 38.1315727390532,
  38.0065727390533, 38.1315727390532,
  38.0065727390533, 38.1315727390532,
  38.0065727390533, 38.1315727390532,
  38.0065727390533, 38.1315727390532,
  38.0065727390533, 38.1315727390532,
  38.0065727390533, 38.1315727390532,
  38.0065727390533, 38.1315727390532 ;

 lon_bnds =
  -83.0625, -82.9375,
  -83.0625, -82.9375,
  -83.0625, -82.9375,
  -83.0625, -82.9375,
  -83.0625, -82.9375,
  -83.0625, -82.9375,
  -83.0625, -82.9375,
  -83.0625, -82.9375 ;

 time_bnds =
  1246435200, 1249084799,
  1277971200, 1280620799,
  1309507200, 1312156799,
  1341129600, 1343779199,
  1372665600, 1375315199,
  1404201600, 1406851199,
  1435737600, 1438387199,
  1467360000, 1470009599 ;
}"""
    
        cdl_file = os.path.join(self.dir, "ints1.cdl")
        handle = open(cdl_file, 'w')
        handle.write(cdl)
        handle.close()

        # run ncgen
        nc_file = os.path.join(self.dir, "ints.SEASON_JJA.88W_34N_77W_41N.nc")
        netcdf.ncgen(cdl_file, nc_file)
        self.file2 = nc_file


        cdl = """netcdf g4.ints.NLDAS_MOS0125_M_002_evcwsfc.20090101-20161231.SEASON_MAM.88W_34N_77W_41N {
dimensions:
	time = UNLIMITED ; // (8 currently)
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	int datayear(time) ;
		datayear:long_name = "Data year" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
	float NLDAS_MOS0125_M_002_evcwsfc(time) ;
		NLDAS_MOS0125_M_002_evcwsfc:cell_methods = "time: mean lat, lon: mean" ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_param_name = "Canopy_water_evaporation" ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_param_short_name = "EVCW" ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_center_id = 7 ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_table_id = 130 ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_param_number = 200 ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_param_id = 1, 7, 130, 200 ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_product_definition_type = "Average" ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_level_type = 1 ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_VectorComponentFlag = "easterlyNortherlyRelative" ;
		NLDAS_MOS0125_M_002_evcwsfc:standard_name = "canopy_water_evaporation" ;
		NLDAS_MOS0125_M_002_evcwsfc:_FillValue = -9999.f ;
		NLDAS_MOS0125_M_002_evcwsfc:quantity_type = "Evaporation" ;
		NLDAS_MOS0125_M_002_evcwsfc:product_short_name = "NLDAS_MOS0125_M" ;
		NLDAS_MOS0125_M_002_evcwsfc:product_version = "002" ;
		NLDAS_MOS0125_M_002_evcwsfc:long_name = "Canopy water evaporation" ;
		NLDAS_MOS0125_M_002_evcwsfc:units = "W/m^2" ;
		NLDAS_MOS0125_M_002_evcwsfc:group_type = "SEASON" ;
		NLDAS_MOS0125_M_002_evcwsfc:group_value = "MAM" ;
		NLDAS_MOS0125_M_002_evcwsfc:coordinates = "time" ;
		NLDAS_MOS0125_M_002_evcwsfc:plot_hint_legend_label = "MAM" ;
	double lat_bnds(time, latv) ;
		lat_bnds:units = "degrees_north" ;
		lat_bnds:cell_methods = "lat: mean" ;
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
		:start_time = "2009-03-01T00:00:00Z" ;
		:end_time = "2016-05-31T23:59:59Z" ;
		:userstartdate = "2009-01-01T00:00:00Z" ;
		:userenddate = "2016-12-31T23:59:59Z" ;
		:title = "Interannual time series Canopy water evaporation monthly 0.125 deg. [NLDAS Model NLDAS_MOS0125_M v002] W/m^2 over 2009-Mar - 2016-May, Region 88.5937W, 34.5703N, 77.3437W, 41.6016N" ;
		:plot_hint_title = "Interannual time series Canopy water evaporation monthly 0.125 deg. [NLDAS Model" ;
		:plot_hint_subtitle = "NLDAS_MOS0125_M v002] W/m^2 over 2009-Mar - 2016-May, Region 88.5937W, 34.5703N, 77.3437W, 41.6016N" ;
		:plot_hint_time_axis_values = "1262304000,1420070400,1577836800" ;
		:plot_hint_time_axis_labels = "2010,2015,2020" ;
		:plot_hint_time_axis_minor = "1230768000,1293840000,1325376000,1356998400,1388534400,1451606400" ;
		:history = "Tue Aug  8 16:42:47 2017: ncatted -a plot_hint_time_axis_values,global,c,c,1262304000,1420070400,1577836800 -a plot_hint_time_axis_labels,global,c,c,2010,2015,2020 -a plot_hint_time_axis_minor,global,c,c,1230768000,1293840000,1325376000,1356998400,1388534400,1451606400 /var/giovanni/session/452EB79C-7C55-11E7-ABCA-C521F1999D63/56FD3C76-7C57-11E7-9260-D168F1999D63/56FF054C-7C57-11E7-9260-D168F1999D63/g4.ints.NLDAS_MOS0125_M_002_evcwsfc.20090101-20161231.SEASON_MAM.88W_34N_77W_41N.nc" ;
		:plot_hint_caption = "- Seasons with missing months are discarded.\n",
			"- DJF seasons are plotted against the year of the January and February data granules." ;
data:

 datayear = 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016 ;

 time = 1235865600, 1267401600, 1298937600, 1330560000, 1362096000, 
    1393632000, 1425168000, 1456790400 ;

 NLDAS_MOS0125_M_002_evcwsfc = -15.41854, -12.1115, -16.26739, -9.990607, 
    -11.71909, -11.03266, -11.68018, -12.01754 ;

 lat_bnds =
  38.0065727390533, 38.1315727390532,
  38.0065727390533, 38.1315727390532,
  38.0065727390533, 38.1315727390532,
  38.0065727390533, 38.1315727390532,
  38.0065727390533, 38.1315727390532,
  38.0065727390533, 38.1315727390532,
  38.0065727390533, 38.1315727390532,
  38.0065727390533, 38.1315727390532 ;

 lon_bnds =
  -83.0625, -82.9375,
  -83.0625, -82.9375,
  -83.0625, -82.9375,
  -83.0625, -82.9375,
  -83.0625, -82.9375,
  -83.0625, -82.9375,
  -83.0625, -82.9375,
  -83.0625, -82.9375 ;

 time_bnds =
  1238515200, 1241164799,
  1270051200, 1272700799,
  1301587200, 1304236799,
  1333209600, 1335859199,
  1364745600, 1367395199,
  1396281600, 1398931199,
  1427817600, 1430467199,
  1459440000, 1462089599 ;
}"""

        cdl_file = os.path.join(self.dir, "ints2.cdl")
        handle = open(cdl_file, 'w')
        handle.write(cdl)
        handle.close()

        # run ncgen
        nc_file = os.path.join(self.dir, "ints.SEASON_MAM.88W_34N_77W_41N.nc")
        netcdf.ncgen(cdl_file, nc_file)
        self.file1 = nc_file


        cdl="""netcdf g4.ints.NLDAS_MOS0125_M_002_evcwsfc.20090101-20161231.SEASON_SON.88W_34N_77W_41N {
dimensions:
	time = UNLIMITED ; // (8 currently)
	latv = 2 ;
	lonv = 2 ;
	nv = 2 ;
variables:
	int datayear(time) ;
		datayear:long_name = "Data year" ;
	int time(time) ;
		time:standard_name = "time" ;
		time:units = "seconds since 1970-01-01 00:00:00" ;
	float NLDAS_MOS0125_M_002_evcwsfc(time) ;
		NLDAS_MOS0125_M_002_evcwsfc:cell_methods = "time: mean lat, lon: mean" ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_param_name = "Canopy_water_evaporation" ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_param_short_name = "EVCW" ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_center_id = 7 ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_table_id = 130 ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_param_number = 200 ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_param_id = 1, 7, 130, 200 ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_product_definition_type = "Average" ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_level_type = 1 ;
		NLDAS_MOS0125_M_002_evcwsfc:GRIB_VectorComponentFlag = "easterlyNortherlyRelative" ;
		NLDAS_MOS0125_M_002_evcwsfc:standard_name = "canopy_water_evaporation" ;
		NLDAS_MOS0125_M_002_evcwsfc:_FillValue = -9999.f ;
		NLDAS_MOS0125_M_002_evcwsfc:quantity_type = "Evaporation" ;
		NLDAS_MOS0125_M_002_evcwsfc:product_short_name = "NLDAS_MOS0125_M" ;
		NLDAS_MOS0125_M_002_evcwsfc:product_version = "002" ;
		NLDAS_MOS0125_M_002_evcwsfc:long_name = "Canopy water evaporation" ;
		NLDAS_MOS0125_M_002_evcwsfc:units = "W/m^2" ;
		NLDAS_MOS0125_M_002_evcwsfc:group_type = "SEASON" ;
		NLDAS_MOS0125_M_002_evcwsfc:group_value = "SON" ;
		NLDAS_MOS0125_M_002_evcwsfc:coordinates = "time" ;
		NLDAS_MOS0125_M_002_evcwsfc:plot_hint_legend_label = "SON" ;
	double lat_bnds(time, latv) ;
		lat_bnds:units = "degrees_north" ;
		lat_bnds:cell_methods = "lat: mean" ;
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
		:start_time = "2009-09-01T00:00:00Z" ;
		:end_time = "2016-11-30T23:59:59Z" ;
		:userstartdate = "2009-01-01T00:00:00Z" ;
		:userenddate = "2016-12-31T23:59:59Z" ;
		:title = "Interannual time series Canopy water evaporation monthly 0.125 deg. [NLDAS Model NLDAS_MOS0125_M v002] W/m^2 over 2009-Sep - 2016-Nov, Region 88.5937W, 34.5703N, 77.3437W, 41.6016N" ;
		:plot_hint_title = "Interannual time series Canopy water evaporation monthly 0.125 deg. [NLDAS Model" ;
		:plot_hint_subtitle = "NLDAS_MOS0125_M v002] W/m^2 over 2009-Sep - 2016-Nov, Region 88.5937W, 34.5703N, 77.3437W, 41.6016N" ;
		:plot_hint_time_axis_values = "1262304000,1420070400,1577836800" ;
		:plot_hint_time_axis_labels = "2010,2015,2020" ;
		:plot_hint_time_axis_minor = "1230768000,1293840000,1325376000,1356998400,1388534400,1451606400" ;
		:history = "Tue Aug  8 16:42:31 2017: ncatted -a plot_hint_time_axis_values,global,c,c,1262304000,1420070400,1577836800 -a plot_hint_time_axis_labels,global,c,c,2010,2015,2020 -a plot_hint_time_axis_minor,global,c,c,1230768000,1293840000,1325376000,1356998400,1388534400,1451606400 /var/giovanni/session/452EB79C-7C55-11E7-ABCA-C521F1999D63/56FD3C76-7C57-11E7-9260-D168F1999D63/56FF054C-7C57-11E7-9260-D168F1999D63/g4.ints.NLDAS_MOS0125_M_002_evcwsfc.20090101-20161231.SEASON_SON.88W_34N_77W_41N.nc" ;
		:plot_hint_caption = "- Seasons with missing months are discarded.\n",
			"- DJF seasons are plotted against the year of the January and February data granules." ;
data:

 datayear = 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016 ;

 time = 1251763200, 1283299200, 1314835200, 1346457600, 1377993600, 
    1409529600, 1441065600, 1472688000 ;

 NLDAS_MOS0125_M_002_evcwsfc = -12.65944, -9.100002, -14.36509, -11.0224, 
    -8.935831, -10.81711, -11.40564, -7.198822 ;

 lat_bnds =
  38.0065727390533, 38.1315727390532,
  38.0065727390533, 38.1315727390532,
  38.0065727390533, 38.1315727390532,
  38.0065727390533, 38.1315727390532,
  38.0065727390533, 38.1315727390532,
  38.0065727390533, 38.1315727390532,
  38.0065727390533, 38.1315727390532,
  38.0065727390533, 38.1315727390532 ;

 lon_bnds =
  -83.0625, -82.9375,
  -83.0625, -82.9375,
  -83.0625, -82.9375,
  -83.0625, -82.9375,
  -83.0625, -82.9375,
  -83.0625, -82.9375,
  -83.0625, -82.9375,
  -83.0625, -82.9375 ;

 time_bnds =
  1254384000, 1257004799,
  1285920000, 1288540799,
  1317456000, 1320076799,
  1349078400, 1351699199,
  1380614400, 1383235199,
  1412150400, 1414771199,
  1443686400, 1446307199,
  1475308800, 1477929599 ;
}"""
        cdl_file = os.path.join(self.dir, "ints3.cdl")
        handle = open(cdl_file, 'w')
        handle.write(cdl)
        handle.close()

        # run ncgen
        nc_file = os.path.join(self.dir, "ints.SEASON_SON.88W_34N_77W_41N.nc")
        netcdf.ncgen(cdl_file, nc_file)
        self.file3 = nc_file
        
        xml_mfst = "<manifest><fileList><file>" + self.file1 + "</file></fileList><fileList>" + \
                   "<file>" + self.file2  + "</file></fileList><fileList>" + \
                   "<file>" + self.file3  + "</file></fileList></manifest>"


        self.xml_mfst_file = os.path.join(self.dir, "mfst.combine+sInTs.SEASON_JJA_MAM_SON.88W_34N_77W_41N.xml")
        handle = open(self.xml_mfst_file, 'w')
        handle.write(xml_mfst)
        handle.close()
 

        bbox_input_file = """<input><referer>https://dev.gesdisc.eosdis.nasa.gov/~rstrub/giovanni/index-debug.html</referer><query>session=452EB79C-7C55-11E7-ABCA-C521F1999D63&amp;service=InTs&amp;starttime=2009-01-01T00:00:00Z&amp;endtime=2016-12-31T23:59:59Z&amp;seasons=MAM,JJA,SON&amp;bbox=-88.5937,34.5703,-77.3437,41.6016&amp;data=NLDAS_MOS0125_M_002_evcwsfc&amp;variableFacets=dataFieldMeasurement%3AEvaporation%3B&amp;portal=GIOVANNI&amp;format=json</query><title>Time Series, Seasonal</title><description>Seasonal (inter annual) time series from 2009 to 2016 for Mar-Apr-May(MAM),Jun-Jul-Aug(JJA),Sep-Oct-Nov(SON) over -88.5937,34.5703,-77.3437,41.6016</description><result id="56FF054C-7C57-11E7-9260-D168F1999D63"><dir>/var/giovanni/session/452EB79C-7C55-11E7-ABCA-C521F1999D63/56FD3C76-7C57-11E7-9260-D168F1999D63/56FF054C-7C57-11E7-9260-D168F1999D63/</dir></result><bbox>-88.5937,34.5703,-77.3437,41.6016</bbox><data>NLDAS_MOS0125_M_002_evcwsfc</data><endtime>2016-12-31T23:59:59Z</endtime><portal>GIOVANNI</portal><seasons>MAM,JJA,SON</seasons><service>InTs</service><session>452EB79C-7C55-11E7-ABCA-C521F1999D63</session><starttime>2009-01-01T00:00:00Z</starttime><variableFacets>dataFieldMeasurement:Evaporation;</variableFacets></input> """


        self.input_file = os.path.join(self.dir, "input.xml")
        handle = open(self.input_file, 'w')
        handle.write(bbox_input_file)
        handle.close()

    def testRunThroughCombinedAscii(self):


        myCmd = 'serialize_ints.py ' + self.dir
        status = runcmd(myCmd)

        expected_bbox = """Title:,"Interannual time series Canopy water evaporation monthly 0.125 deg. [NLDAS Model NLDAS_MOS0125_M v002] W/m^2 over 2009-Mar - 2016-May, Region 88.5937W, 34.5703N, 77.3437W, 41.6016N"
User Start Date:,2009-01-01T00:00:00Z
User End Date:,2016-12-31T23:59:59Z
Bounding Box:,"-88.5937,34.5703,-77.3437,41.6016"
URL to Reproduce Results:,"https://dev.gesdisc.eosdis.nasa.gov/~rstrub/giovanni/index-debug.html#service=InTs&starttime=2009-01-01T00%3A00%3A00Z&endtime=2016-12-31T23%3A59%3A59Z&seasons=MAM%2CJJA%2CSON&bbox=-88.5937%2C34.5703%2C-77.3437%2C41.6016&data=NLDAS_MOS0125_M_002_evcwsfc&variableFacets=dataFieldMeasurement%3AEvaporation%3B&portal=GIOVANNI&format=json"
Fill Value:,-9999.0
Units:,W/m^2
Variable Name:,NLDAS_MOS0125_M_002_evcwsfc



TIME,MAM,JJA,SON
2009,-15.4185,-15.943,-12.6594
2010,-12.1115,-13.77,-9.1
2011,-16.2674,-12.4954,-14.3651
2012,-9.99061,-12.1385,-11.0224
2013,-11.7191,-15.9496,-8.93583
2014,-11.0327,-14.0602,-10.8171
2015,-11.6802,-14.5676,-11.4056
2016,-12.0175,-13.816,-7.19882
"""
        expected_file = os.path.join(self.dir, "csv.expected")
        handle = open(expected_file, 'w')
        handle.write(expected_bbox)
        handle.close()

        status = runcmd("diff " + expected_file + " " + os.path.join(self.dir, "ints.MAM-JJA-SON.88W_34N_77W_41N.csv"))
        self.assertEqual(status, 0, "Combined ASCII output of interannual time series with bbox")

        #self.cleanup()
        #os.remove(self.xml_mfst_file)


if __name__ == "__main__":
    unittest.main()

