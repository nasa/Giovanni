"""
Tests for the agiovanni.map_plot module.
"""

__author__ = "Christine Smit <christine.e.smit@nasa.gov>"

import unittest
import tempfile
import shutil
import os

import agiovanni.netcdf as netcdf
import python_map_visualizer as pmv


class IntegrationTest(unittest.TestCase):

    def setUp(self):
        self.dir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.dir)

    def runPlotTest(self, cdl, sld_str, world_file_str, variable_name=None, bbox=None):
        # create the netcdf file
        cdl_file = os.path.join(self.dir, "data.cdl")
        handle = open(cdl_file, "w")
        handle.write(cdl)
        handle.close()
        nc_file = os.path.join(self.dir, "data.nc")
        netcdf.ncgen(cdl_file, nc_file)

        # create the sld file
        sld_file = os.path.join(self.dir, "palette.sld")
        handle = open(sld_file, "w")
        handle.write(sld_str)
        handle.close()

        output_file = os.path.join(self.dir, "out.png")
        world_file = os.path.join(self.dir, "out.wld")
        argv = [nc_file, output_file, "--sld", sld_file, "--world", world_file]

        if variable_name is not None:
            argv.append("--variable")
            argv.append(variable_name)

        if bbox is not None:
            [west,south,east,north] = bbox.split(",")
            argv.append("--west")
            argv.append(west)
            argv.append("--south")
            argv.append(south)
            argv.append("--east")
            argv.append(east)
            argv.append("--north")
            argv.append(north)

        pmv.main(argv)

        self.assertTrue(os.path.exists(output_file), "Output file created")

        self.assertTrue(os.path.exists(world_file), "World file created")
        handle = open(world_file, 'r')
        test_world = handle.read()
        handle.close()

        self.assertEqual(world_file_str, test_world, "World file is correct")

    def runContourTest(self, cdl, sld_str, world_file_str):
        # create the netcdf file
        cdl_file = os.path.join(self.dir, "data.cdl")
        handle = open(cdl_file, "w")
        handle.write(cdl)
        handle.close()
        nc_file = os.path.join(self.dir, "data.nc")
        netcdf.ncgen(cdl_file, nc_file)

        # create the sld file
        sld_file = os.path.join(self.dir, "palette.sld")
        handle = open(sld_file, "w")
        handle.write(sld_str)
        handle.close()

        output_file = os.path.join(self.dir, "out.png")
        world_file = os.path.join(self.dir, "out.wld")

        argv = [nc_file, output_file, "--sld",
                sld_file, '--contour', "--world", world_file]
        pmv.main(argv)

        self.assertTrue(os.path.exists(output_file), "Output file created")

        self.assertTrue(os.path.exists(world_file), "World file created")
        handle = open(world_file, 'r')
        test_world = handle.read()
        handle.close()

        self.assertEqual(world_file_str, test_world, "World file is correct")

    def testOmi(self):
        cdl = """netcdf g4.timeAvgMap.OMAERUVd_003_FinalAerosolExtOpticalDepth500.20050202-20050202.74W_41N_66W_48N {
dimensions:
    lat = 8 ;
    lon = 8 ;
variables:
    float OMAERUVd_003_FinalAerosolExtOpticalDepth500(lat, lon) ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth500:_FillValue = -1.267651e+30f ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth500:units = "1" ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth500:title = "Final Aerosol Extinction Optical Depth at 500 nm" ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth500:UniqueFieldDefinition = "OMI-Specific" ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth500:missing_value = -1.267651e+30f ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth500:origname = "FinalAerosolExtOpticalDepth500" ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth500:fullnamepath = "/HDFEOS/GRIDS/Aerosol NearUV Grid/Data Fields/FinalAerosolExtOpticalDepth500" ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth500:orig_dimname_list = "XDim " ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth500:standard_name = "finalaerosolextopticaldepth500" ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth500:quantity_type = "Total Aerosol Optical Depth" ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth500:product_short_name = "OMAERUVd" ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth500:product_version = "003" ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth500:long_name = "Aerosol Optical Depth 500 nm" ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth500:coordinates = "lat lon" ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth500:cell_methods = "time: mean time: mean" ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth500:latitude_resolution = 1. ;
        OMAERUVd_003_FinalAerosolExtOpticalDepth500:longitude_resolution = 1. ;
    float lat(lat) ;
        lat:units = "degrees_north" ;
        lat:standard_name = "latitude" ;
        lat:long_name = "Latitude" ;
    float lon(lon) ;
        lon:units = "degrees_east" ;
        lon:standard_name = "longitude" ;
        lon:long_name = "Longitude" ;
    int time ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
        time:cell_methods = "time: mean time: mean" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2005-02-02T00:00:00Z" ;
        :end_time = "2005-02-02T23:59:59Z" ;
        :history = "Fri Aug 14 16:39:29 2015: ncatted -a valid_range,,d,, -O -o timeAvgMap.OMAERUVd_003_FinalAerosolExtOpticalDepth500.20050202-20050202.74W_41N_66W_48N.nc timeAvgMap.OMAERUVd_003_FinalAerosolExtOpticalDepth500.20050202-20050202.74W_41N_66W_48N.nc\n",
            "Fri Aug 14 16:39:28 2015: ncatted -O -a title,global,o,c,OMAERUVd_003_FinalAerosolExtOpticalDepth500 Averaged over 2005-02-02 to 2005-02-02 timeAvgMap.OMAERUVd_003_FinalAerosolExtOpticalDepth500.20050202-20050202.74W_41N_66W_48N.nc\n",
            "Fri Aug 14 16:39:28 2015: ncks -x -v time -o timeAvgMap.OMAERUVd_003_FinalAerosolExtOpticalDepth500.20050202-20050202.74W_41N_66W_48N.nc -O timeAvgMap.OMAERUVd_003_FinalAerosolExtOpticalDepth500.20050202-20050202.74W_41N_66W_48N.nc\n",
            "Fri Aug 14 16:39:28 2015: ncwa -o timeAvgMap.OMAERUVd_003_FinalAerosolExtOpticalDepth500.20050202-20050202.74W_41N_66W_48N.nc -a time -O timeAvgMap.OMAERUVd_003_FinalAerosolExtOpticalDepth500.20050202-20050202.74W_41N_66W_48N.nc\n",
            "Fri Aug 14 16:39:28 2015: ncra -D 2 -H -O -o timeAvgMap.OMAERUVd_003_FinalAerosolExtOpticalDepth500.20050202-20050202.74W_41N_66W_48N.nc -d lat,41.337900,48.896500 -d lon,-74.003900,-66.445300" ;
        :NCO = "4.4.4" ;
        :title = "Time Averaged Map of Aerosol Optical Depth 500 nm daily 1 deg. [OMI OMAERUVd v003] over 2005-02-02, Region 74.0039W, 41.3379N, 66.4453W, 48.8965N " ;
        :userstartdate = "2005-02-02T00:00:00Z" ;
        :userenddate = "2005-02-02T23:59:59Z" ;
        :plot_hint_title = "Time Averaged Map of Aerosol Optical Depth 500 nm daily 1 deg. [OMI OMAERUVd v003]" ;
        :plot_hint_subtitle = "over 2005-02-02, Region 74.0039W, 41.3379N, 66.4453W, 48.8965N " ;
data:

 OMAERUVd_003_FinalAerosolExtOpticalDepth500 =
  0.2414, 0.2432, 0.2358, 0.215, 0.2122, _, _, _,
  _, _, _, 0.1969, _, _, _, _,
  _, _, _, _, 0.1725, 0.046, _, _,
  _, 0.3802, 0.2503, _, _, 0.1731, 0.079, 0.1743,
  _, _, 0.2494, _, _, _, 0.2717, 0.1638,
  _, _, 0.5048, 0.1843, 0.1781, 0.2838, 0.1441, 0.2218,
  _, 0.3903, 0.2613, 0.1986, 0.2027, 0.1813, 0.1348, 0.1931,
  _, 0.1502, _, 0.2362, 0.2025, 0.1893, 0.1957, 0.1761 ;

 lat = 41.5, 42.5, 43.5, 44.5, 45.5, 46.5, 47.5, 48.5 ;

 lon = -73.5, -72.5, -71.5, -70.5, -69.5, -68.5, -67.5, -66.5 ;

 time = 1107302400 ;
}
"""
        sld_str = """<?xml version="1.0"?>
<StyledLayerDescriptor xmlns="http://www.opengis.net/sld" xmlns:se="http://www.opengis.net/se" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.1.0" xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.1.0/StyledLayerDescriptor.xsd">
  <NamedLayer>
    <se:Name>sequential_rd_9_sld</se:Name>
    <UserStyle>
      <se:Name>Reds (Seq), 9</se:Name>
      <se:FeatureTypeStyle>
        <se:Rule>
          <se:RasterSymbolizer>
            <se:Opacity>1.0</se:Opacity>
            <se:ColorMap>
              <se:Categorize fallbackValue="#ff00ff">
                <se:LookupValue>Rasterdata</se:LookupValue>
                <se:Value>#fff5f0</se:Value>
                <se:Threshold>0</se:Threshold>
                <se:Value>#fee0d2</se:Value>
                <se:Threshold>0.143</se:Threshold>
                <se:Value>#fcbba1</se:Value>
                <se:Threshold>0.286</se:Threshold>
                <se:Value>#fc9272</se:Value>
                <se:Threshold>0.429</se:Threshold>
                <se:Value>#fb6a4a</se:Value>
                <se:Threshold>0.572</se:Threshold>
                <se:Value>#ef3b2c</se:Value>
                <se:Threshold>0.715</se:Threshold>
                <se:Value>#cb181d</se:Value>
                <se:Threshold>0.857</se:Threshold>
                <se:Value>#a50f15</se:Value>
                <se:Threshold>1</se:Threshold>
                <se:Value>#67000d</se:Value>
              </se:Categorize>
            </se:ColorMap>
          </se:RasterSymbolizer>
        </se:Rule>
      </se:FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
"""
        world_file_string = """0.007812
0
0
-0.007812
-73.996094
48.996094
"""
        self.runPlotTest(cdl, sld_str, world_file_string)
        self.runPlotTest(cdl, sld_str, world_file_string,
                         variable_name="OMAERUVd_003_FinalAerosolExtOpticalDepth500")
        self.runPlotTest(cdl, sld_str, world_file_string,
                         bbox="-180,-90,180,90")
        self.runContourTest(cdl, sld_str, world_file_string)

if __name__ == "__main__":
    unittest.main()
