#! /bin/env python

"""
NAME
t_NcFile.py - Unit test script of NcFile py module

AUTHORS
Jianfu Pan, 04/26/2012, Initial version
"""

import os
import unittest
import NcFile

class testNcFile(unittest.TestCase):
    def setUp(self):
        self.seq = range(10)
        self.ncfile = NcFile.NcFile("t_NcFile.nc")

    def testNcfile(self):
        self.assertTrue(self.ncfile, "Fail to create NcFile on t_NcFile.nc")

    def testGetAttribute(self):
        attrValue = self.ncfile.get_attribute('title', 'h5__HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388')
        self.assertEqual(attrValue, "Final Aerosol Absorption Optical Depth at 388 nm", "Attribute error: expect {1} actual {0}")

    def testGetAllDimensions(self):
        dimlist = self.ncfile.get_all_dimensions()
        dimlist.sort()
        self.assertEqual(dimlist, ['lat','lon'], "Incorrect dimensions")

    def testGetFillvalue(self):
        fill = self.ncfile.get_fillvalue()
        self.assertEqual(str(fill), '-1.26765e+30', "Incorrect fillvalue "+str(fill))

    def testGetLatitudeDimension(self):
        latDim = self.ncfile.get_latitude_dimension()
        self.assertEqual(latDim, "lat", "Incorrect latitude dimension")

    def testGetLongitudeDimension(self):
        lonDim = self.ncfile.get_longitude_dimension()
        self.assertEqual(lonDim, "lon", "Incorrect longitude dimension")

    def testGetTimeDimension(self):
        timeDim = self.ncfile.get_time_dimension()
        self.assertEqual(timeDim, None, "Incorrect time dimension")

    def testGetRegionLabel(self):
        bbox = self.ncfile.get_region_label()
        self.assertEqual(bbox, "4.5W-5.5E, 5.5S-4.5N", "Incorrect region label")

    def testSnap(self):
        bbox = self.ncfile.subset_bbox_cmd_pyver('1.1,2.1,1.2,2.2')
        self.assertEqual(bbox, "1.15,2.15,1.15,2.15", "Incorrect point snapping")

    def testBenignSnap(self):
        bbox = self.ncfile.subset_bbox_cmd_pyver('1.1,2.1,8.2,9.2')
        self.assertEqual(bbox, "1.1,2.1,8.2,9.2", "bbox should remain the same")


ncdump = """
netcdf in {
dimensions:
	lon = 11 ;
	lat = 11 ;
variables:
	float lon(lon) ;
		lon:grads_dim = "x" ;
		lon:grads_mapping = "linear" ;
		lon:grads_size = "360" ;
		lon:units = "degrees_east" ;
		lon:long_name = "longitude" ;
		lon:minimum = -180.f ;
		lon:maximum = 180.f ;
		lon:resolution = 1.f ;
	float lat(lat) ;
		lat:grads_dim = "y" ;
		lat:grads_mapping = "linear" ;
		lat:grads_size = "180" ;
		lat:units = "degrees_north" ;
		lat:long_name = "latitude" ;
		lat:minimum = -90.f ;
		lat:maximum = 90.f ;
		lat:resolution = 1.f ;
	float h5__HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388(lat, lon) ;
		h5__HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388:h5__HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388.units = "NoUnits" ;
		h5__HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388:h5__HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388.title = "Final Aerosol Absorption Optical Depth at 388 nm" ;
		h5__HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388:h5__HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388.UniqueFieldDefinition = "OMI-Specific" ;
		h5__HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388:h5__HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388.scale_factor = 1. ;
		h5__HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388:h5__HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388.add_offset = 0. ;
		h5__HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388:_FillValue = -1.26765e+30f ;
		h5__HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388:units = "NoUnits" ;
		h5__HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388:title = "Final Aerosol Absorption Optical Depth at 388 nm" ;
		h5__HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388:UniqueFieldDefinition = "OMI-Specific" ;
		h5__HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388:scale_factor = 1. ;
		h5__HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388:add_offset = 0. ;
		h5__HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388:missing_value = -1.26765e+30f ;
		h5__HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388:fonc_original_name = "_HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388" ;

// global attributes:
		:title = "NASA HDFEOS5 Grid" ;
		:Conventions = "CF-1.4" ;
		:dataType = "Grid" ;
data:

 lon = -4.5, -3.5, -2.5, -1.5, -0.5, 0.5, 1.5, 2.5, 3.5, 4.5, 5.5 ;

 lat = -5.5, -4.5, -3.5, -2.5, -1.5, -0.5, 0.5, 1.5, 2.5, 3.5, 4.5 ;

 h5__HDFEOS_GRIDS_Aerosol_NearUV_Grid_Data_Fields_FinalAerosolAbsOpticalDepth388 =
  -1.26765e+30, -1.26765e+30, -1.26765e+30, -1.26765e+30, -1.26765e+30, 
    -1.26765e+30, -1.26765e+30, -1.26765e+30, -1.26765e+30, 
    -1.26765e+30, -1.26765e+30,
  -1.26765e+30, -1.26765e+30, -1.26765e+30, -1.26765e+30, -1.26765e+30, 
    -1.26765e+30, -1.26765e+30, -1.26765e+30, -1.26765e+30, 
    -1.26765e+30, -1.26765e+30,
  -1.26765e+30, 0.0684, -1.26765e+30, -1.26765e+30, 0.1196, 0.0661, 
    0.0648, 0.072, 0.0896, 0.085, -1.26765e+30,
  0.0672, 0.0772, 0.0745, 0.0676, 0.0717, 0.0701, 0.0757, 0.0879, 0.1147, 
    -1.26765e+30, -1.26765e+30,
  0.0905, 0.0833, 0.0734, 0.0749, 0.0857, 0.0838, 0.0874, 0.0716, 0.0848, 
    0.1245, -1.26765e+30,
  0.0771, 0.0859, 0.0727, 0.0672, 0.0836, -1.26765e+30, 0.0696, 0.0708, 
    0.0885, -1.26765e+30, -1.26765e+30,
  0.073, 0.0859, 0.0801, 0.0686, 0.0676, -1.26765e+30, -1.26765e+30, 
    -1.26765e+30, -1.26765e+30, -1.26765e+30, -1.26765e+30,
  0.1016, 0.1106, 0.0852, 0.0678, -1.26765e+30, -1.26765e+30, 
    -1.26765e+30, -1.26765e+30, 0.0898, -1.26765e+30, -1.26765e+30,
  0.0693, 0.0755, 0.0971, 0.0733, 0.0845, -1.26765e+30, 0.146, 0.1097, 
    0.1307, -1.26765e+30, -1.26765e+30,
  0.0817, 0.1014, 0.0964, 0.0961, 0.1, 0.0859, 0.1092, 0.1306, -1.26765e+30, 
    -1.26765e+30, -1.26765e+30,
  0.1381, 0.1455, -1.26765e+30, 0.0711, 0.0705, 0.1011, 0.1402, 0.1481, 
    -1.26765e+30, -1.26765e+30, 0.1522 ;
}
"""
datafile = open("t_NcFile.ncdump", "w")
datafile.write(ncdump)
datafile.close()
os.system("ncgen -b -o t_NcFile.nc t_NcFile.ncdump")

unittest.main()
