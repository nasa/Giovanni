"""
Tests for the agiovanni.map_plot module.
"""

__author__ = "Christine Smit <christine.e.smit@nasa.gov>"

import unittest
import tempfile
import shutil
import os

import agiovanni.netcdf as netcdf
import agiovanni.map_plot as mp


class IntegrationTest(unittest.TestCase):

    def setUp(self):
        self.dir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.dir)

    def runPlotTest(self, cdl, sld_str, world_file_str=None, variable_name=None,
                    north=90, south=-90, west=-180, east=180, height=None,
                    width=None, inflation_factor=None):
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

        v = mp.Visualize(nc_file, sld_file, variable_name=variable_name,
                         north=north, south=south, west=west, east=east,
                         height=height, width=width,
                         inflation_factor=inflation_factor)
        output_file = os.path.join(self.dir, "out.png")
        v.plot(output_file)

        self.assertTrue(os.path.exists(output_file), "Output file created")

        world_file = os.path.join(self.dir, "out.wld")
        v.create_world_file(world_file)

        self.assertTrue(os.path.exists(world_file), "World file created")
        handle = open(world_file, 'r')
        test_world = handle.read()
        handle.close()

        if world_file_str is not None:
            self.assertEqual(world_file_str, test_world,
                             "World file is correct")

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

        v = mp.Visualize(nc_file, sld_file)
        output_file = os.path.join(self.dir, "out.png")
        v.contour(output_file)
        self.assertTrue(os.path.exists(output_file), "Output file created")

        world_file = os.path.join(self.dir, "out.wld")
        v.create_world_file(world_file)

        self.assertTrue(os.path.exists(world_file), "World file created")
        handle = open(world_file, 'r')
        test_world = handle.read()
        handle.close()

        self.assertEqual(world_file_str, test_world, "World file is correct")

    def testNoLatLonResolution(self):
        '''
        This tests that we can handle data from the difference of time averaged
        map service and animation, which don't have latitude and longitude
        resolution attributes.
        '''
        cdl = '''netcdf g4.timeAvgDiffMap.OMAERUVd_003_FinalAerosolSingleScattAlb388+OMAERUVd_003_FinalAerosolSingleScattAlb500.20050101-20050101.81W_34N_77W_39N {
dimensions:
    time = UNLIMITED ; // (1 currently)
    lat = 4 ;
    lon = 5 ;
variables:
    int dataday(time) ;
        dataday:long_name = "Standardized Date Label" ;
        dataday:cell_methods = "time: mean" ;
    float lat(lat) ;
        lat:units = "degrees_north" ;
        lat:standard_name = "latitude" ;
        lat:long_name = "Latitude" ;
    float lon(lon) ;
        lon:units = "degrees_east" ;
        lon:standard_name = "longitude" ;
        lon:long_name = "Longitude" ;
    int time(time) ;
        time:standard_name = "time" ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
        time:cell_methods = "time: mean" ;
    float time_matched_difference(time, lat, lon) ;
        time_matched_difference:_FillValue = -1.267651e+30f ;
        time_matched_difference:units = "NoUnits" ;
        time_matched_difference:title = "Final Aerosol Single Scattering Albedo at 500 nm" ;
        time_matched_difference:UniqueFieldDefinition = "OMI-Specific" ;
        time_matched_difference:missing_value = -1.267651e+30f ;
        time_matched_difference:origname = "FinalAerosolSingleScattAlb500" ;
        time_matched_difference:fullnamepath = "/HDFEOS/GRIDS/Aerosol NearUV Grid/Data Fields/FinalAerosolSingleScattAlb500" ;
        time_matched_difference:orig_dimname_list = "XDim " ;
        time_matched_difference:standard_name = "finalaerosolsinglescattalb500" ;
        time_matched_difference:quantity_type = "Albedo" ;
        time_matched_difference:product_short_name = "OMAERUVd" ;
        time_matched_difference:product_version = "003" ;
        time_matched_difference:long_name = "Aerosol Single Scattering Albedo 500 nm daily 1 deg. [OMI OMAERUVd v003] NoUnits minus Aerosol Single Scattering Albedo 388 nm daily 1 deg. [OMI OMAERUVd v003] NoUnits" ;
        time_matched_difference:coordinates = "time lat lon" ;
        time_matched_difference:cell_methods = "time: mean" ;
        time_matched_difference:plot_hint_legend_label = "OMAERUVd_003_FinalAerosolSingleScattAlb500 minus\n",
            "OMAERUVd_003_FinalAerosolSingleScattAlb388" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "2005-01-01T00:00:00Z" ;
        :end_time = "2005-01-01T23:59:59Z" ;
        :temporal_resolution = "daily" ;
        :history = "Thu Nov 19 18:27:50 2015: ncdiff -O ./filesFmoQV.txt.1.timeavg.nc ./filesFmoQV.txt.0.timeavg.nc timeAvgDiffMap.OMAERUVd_003_FinalAerosolSingleScattAlb388+OMAERUVd_003_FinalAerosolSingleScattAlb500.20050101-20050101.81W_34N_77W_39N.nc\n",
            "Thu Nov 19 18:27:50 2015: ncrename -v OMAERUVd_003_FinalAerosolSingleScattAlb500,time_matched_difference -O -o ./filesFmoQV.txt.1.timeavg.nc ./filesFmoQV.txt.1.timeavg.nc\n",
            "Thu Nov 19 18:27:50 2015: ncra -D 2 -H -O -o ./filesFmoQV.txt.1.timeavg.nc -d lat,34.570300,39.492200 -d lon,-81.562500,-77.343700" ;
        :NCO = "4.4.4" ;
        :userstartdate = "2005-01-01T00:00:00Z" ;
        :userenddate = "2005-01-01T23:59:59Z" ;
        :title = "Map, Difference of Time Averaged over 2005-01-01, Region 81.5625W, 34.5703N, 77.3437W, 39.4922N  of Aerosol Single Scattering Albedo 500 nm daily 1 deg. [OMI OMAERUVd v003] NoUnits minus Aerosol Single Scattering Albedo 388 nm daily 1 deg. [OMI OMAERUVd v003] NoUnits" ;
        :plot_hint_title = "Map, Difference of Time Averaged over 2005-01-01, Region 81.5625W, 34.5703N, 77.3437W, 39.4922N " ;
        :plot_hint_subtitle = "Aerosol Single Scattering Albedo 500 nm daily 1 deg. [OMI OMAERUVd v003] NoUnits minus\n",
            "Aerosol Single Scattering Albedo 388 nm daily 1 deg. [OMI OMAERUVd v003] NoUnits" ;
data:

 dataday = 0 ;

 lat = 35.5, 36.5, 37.5, 38.5 ;

 lon = -81.5, -80.5, -79.5, -78.5, -77.5 ;

 time = 1104537600 ;

 time_matched_difference =
  -0.0005999804, -0.004299998, _, -0.006500006, -0.008300006,
  _, -0.002799988, -0.00849998, -0.0097, -0.007799983,
  _, _, _, -0.005499959, -0.004400015,
  _, _, _, _, -0.005199969 ;
}
'''
        sld_str = '''<?xml version="1.0"?>
<StyledLayerDescriptor xmlns="http://www.opengis.net/sld" xmlns:se="http://www.opengis.net/se" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.1.0" xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.1.0/StyledLayerDescriptor.xsd">
  <NamedLayer>
    <se:Name>time_matched_difference_sld</se:Name>
    <UserStyle>
      <se:Name>Blue-Yellow-Red (Div), 12</se:Name>
      <se:FeatureTypeStyle>
        <se:Rule>
          <se:RasterSymbolizer>
            <se:Opacity>1.0</se:Opacity>
            <se:ColorMap>
              <se:Categorize fallbackValue="#ff00ff">
                <se:LookupValue>Rasterdata</se:LookupValue>
                <se:Value>#0000FF</se:Value>
                <se:Threshold>-0.01</se:Threshold>
                <se:Value>#2288FF</se:Value>
                <se:Threshold>-0.008</se:Threshold>
                <se:Value>#55AAFF</se:Value>
                <se:Threshold>-0.006</se:Threshold>
                <se:Value>#99CCFF</se:Value>
                <se:Threshold>-0.004</se:Threshold>
                <se:Value>#CCEEFF</se:Value>
                <se:Threshold>-0.002</se:Threshold>
                <se:Value>#EEFFFF</se:Value>
                <se:Threshold>0</se:Threshold>
                <se:Value>#FFFF44</se:Value>
                <se:Threshold>0.002</se:Threshold>
                <se:Value>#FFE300</se:Value>
                <se:Threshold>0.004</se:Threshold>
                <se:Value>#FF9933</se:Value>
                <se:Threshold>0.006</se:Threshold>
                <se:Value>#FF5500</se:Value>
                <se:Threshold>0.008</se:Threshold>
                <se:Value>#FF0000</se:Value>
                <se:Threshold>0.01</se:Threshold>
                <se:Value>#DD0000</se:Value>
              </se:Categorize>
            </se:ColorMap>
          </se:RasterSymbolizer>
          <se:Name>NoUnits</se:Name>
        </se:Rule>
      </se:FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
'''
        world_file_str = '''0.004902
0
0
-0.004902
-81.997549
38.997549
'''

        self.runPlotTest(cdl, sld_str, world_file_str)

    def testPoint(self):
        '''
        This tests that we can handle point data.
        '''
        cdl = '''netcdf correlation.TRMM_3B43_006_precipitation+NLDAS_FORA0125_M_002_apcpsfc.20000101T000000-20001231T235959 {
dimensions:
    lat = 1 ;
    lon = 1 ;
variables:
    double correlation(lat, lon) ;
        correlation:long_name = "Correlation of Precipitation Rate monthly 0.25 deg. [TRMM TRMM_3B43 v6] mm/hr vs. Precipitation Total monthly 0.125 deg. [NLDAS Model NLDAS_FORA0125_M v002] kg/m^2" ;
        correlation:_FillValue = 9.96920996838687e+36 ;
        correlation:quantity_type = "correlation" ;
        correlation:plot_hint_minval = -1. ;
        correlation:plot_hint_maxval = 1. ;
        correlation:latitude_resolution = 0.25 ;
        correlation:longitude_resolution = 0.25 ;
        correlation:plot_hint_title = "Correlation for 2000-Jan - 2000-12-01" ;
        correlation:plot_hint_subtitle = "1st Variable: Precipitation Rate monthly 0.25 deg. [TRMM TRMM_3B43 v6] mm/hr\n",
            "2nd Variable: Precipitation Total monthly 0.125 deg. [NLDAS Model NLDAS_FORA0125_M v002] kg/m^2" ;
    double lat(lat) ;
        lat:long_name = "latitude" ;
        lat:standard_name = "latitude" ;
        lat:units = "degrees_north" ;
    double lon(lon) ;
        lon:long_name = "longitude" ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    int n_samples(lat, lon) ;
        n_samples:long_name = "Number of samples" ;
        n_samples:quantity_type = "count" ;
        n_samples:units = "count" ;
        n_samples:latitude_resolution = 0.25 ;
        n_samples:longitude_resolution = 0.25 ;
        n_samples:plot_hint_title = "Time matched sample size for 2000-Jan - 2000-12-01" ;
        n_samples:plot_hint_subtitle = "1st Variable: Precipitation Rate monthly 0.25 deg. [TRMM TRMM_3B43 v6] mm/hr\n",
            "2nd Variable: Precipitation Total monthly 0.125 deg. [NLDAS Model NLDAS_FORA0125_M v002] kg/m^2" ;
    double offset(lat, lon) ;
        offset:long_name = "offset" ;
        offset:_FillValue = 9.96920996838687e+36 ;
    double slope(lat, lon) ;
        slope:long_name = "slope" ;
        slope:_FillValue = 9.96920996838687e+36 ;

// global attributes:
        :Conventions = "CF-1.4" ;
        :title = "Correlation of Precipitation Rate monthly 0.25 deg. [TRMM TRMM_3B43 v6] mm/hr vs. Precipitation Total monthly 0.125 deg. [NLDAS Model NLDAS_FORA0125_M v002] kg/m^2" ;
        :plot_hint_title = "Correlation (top) and Sample Size (bottom) for 2000-01-01 - 2000-12-31" ;
        :plot_hint_subtitle = "1st Variable: Precipitation Rate monthly 0.25 deg. [TRMM TRMM_3B43 v6] mm/hr~C~2nd Variable: Precipitation Total monthly 0.125 deg. [NLDAS Model NLDAS_FORA0125_M v002] kg/m^2" ;
        :matched_start_time = "2000-01-01T00:00:00Z" ;
        :matched_end_time = "2000-12-01T23:59:59Z" ;
        :input_temporal_resolution = "monthly" ;
        :NCO = "4.4.4" ;
data:

 correlation =
  0.972444694893961 ;

 lat = 37.375 ;

 lon = -105.375 ;

 n_samples =
  12 ;

 offset =
  7.66858499906377 ;

 slope =
  915.307091984307 ;
}
'''
        sld_str = '''<?xml version="1.0"?>
<StyledLayerDescriptor xmlns="http://www.opengis.net/sld" xmlns:se="http://www.opengis.net/se" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.1.0" xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.1.0/StyledLayerDescriptor.xsd">
  <NamedLayer>
    <se:Name>correlation_sld</se:Name>
    <UserStyle>
      <se:Name>Blue-Yellow-Red (Div), 12</se:Name>
      <se:FeatureTypeStyle>
        <se:Rule>
          <se:RasterSymbolizer>
            <se:Opacity>1.0</se:Opacity>
            <se:ColorMap>
              <se:Categorize fallbackValue="#ff00ff">
                <se:LookupValue>Rasterdata</se:LookupValue>
                <se:Value>#0000FF</se:Value>
                <se:Threshold>-1</se:Threshold>
                <se:Value>#2288FF</se:Value>
                <se:Threshold>-0.8</se:Threshold>
                <se:Value>#55AAFF</se:Value>
                <se:Threshold>-0.6</se:Threshold>
                <se:Value>#99CCFF</se:Value>
                <se:Threshold>-0.4</se:Threshold>
                <se:Value>#CCEEFF</se:Value>
                <se:Threshold>-0.2</se:Threshold>
                <se:Value>#EEFFFF</se:Value>
                <se:Threshold>0</se:Threshold>
                <se:Value>#FFFF44</se:Value>
                <se:Threshold>0.2</se:Threshold>
                <se:Value>#FFE300</se:Value>
                <se:Threshold>0.4</se:Threshold>
                <se:Value>#FF9933</se:Value>
                <se:Threshold>0.6</se:Threshold>
                <se:Value>#FF5500</se:Value>
                <se:Threshold>0.8</se:Threshold>
                <se:Value>#FF0000</se:Value>
                <se:Threshold>1.0</se:Threshold>
                <se:Value>#DD0000</se:Value>
              </se:Categorize>
            </se:ColorMap>
          </se:RasterSymbolizer>
          <se:Name>1</se:Name>
        </se:Rule>
      </se:FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
'''
        world_file_str = '''0.000244
0
0
-0.000244
-105.499878
37.499878
'''
        self.runPlotTest(cdl, sld_str, world_file_str)

    def testMerra(self):
        '''
        This tests that the world file doesn't start at less than -180 degrees
        longitude. It also tests to make sure that the world file specifies the
        center of the first pixel, not the left top corner.
        '''
        cdl = '''netcdf g4.timeAvgMap.MAIMNPANA_5_2_0_H.850hPa.19900101-19900131.175E_22S_175W_15S {
dimensions:
    lat = 14 ;
    lon = 540 ;
variables:
    double Height ;
        Height:long_name = "vertical level" ;
        Height:units = "hPa" ;
        Height:positive = "down" ;
        Height:coordinate = "pressure" ;
        Height:standard_name = "pressure" ;
        Height:formula_term = "unknown" ;
        Height:fullpath = "Height:EOSGRID" ;
        Height:cell_methods = "Height: mean" ;
    float MAIMNPANA_5_2_0_H(lat, lon) ;
        MAIMNPANA_5_2_0_H:_FillValue = 1.e+15f ;
        MAIMNPANA_5_2_0_H:cell_methods = "record: mean time: mean Height: mean time: mean" ;
        MAIMNPANA_5_2_0_H:coordinates = "lat lon" ;
        MAIMNPANA_5_2_0_H:fmissing_value = 1.e+15f ;
        MAIMNPANA_5_2_0_H:fullpath = "/EOSGRID/Data Fields/H" ;
        MAIMNPANA_5_2_0_H:latitude_resolution = 0.5 ;
        MAIMNPANA_5_2_0_H:long_name = "Geopotential Height" ;
        MAIMNPANA_5_2_0_H:longitude_resolution = 0.666667 ;
        MAIMNPANA_5_2_0_H:missing_value = 1.e+15f ;
        MAIMNPANA_5_2_0_H:product_short_name = "MAIMNPANA" ;
        MAIMNPANA_5_2_0_H:product_version = "5.2.0" ;
        MAIMNPANA_5_2_0_H:quantity_type = "Geopotential" ;
        MAIMNPANA_5_2_0_H:standard_name = "geopotential_height" ;
        MAIMNPANA_5_2_0_H:units = "m" ;
        MAIMNPANA_5_2_0_H:vmax = 1.e+30f ;
        MAIMNPANA_5_2_0_H:vmin = -1.e+30f ;
        MAIMNPANA_5_2_0_H:z_slice = "850hPa" ;
        MAIMNPANA_5_2_0_H:z_slice_type = "pressure" ;
    double lat(lat) ;
        lat:long_name = "Latitude" ;
        lat:units = "degrees_north" ;
        lat:fullpath = "YDim:EOSGRID" ;
        lat:standard_name = "latitude" ;
    double lon(lon) ;
        lon:fullpath = "XDim:EOSGRID" ;
        lon:long_name = "Longitude" ;
        lon:standard_name = "longitude" ;
        lon:units = "degrees_east" ;
    double time ;
        time:begin_date = 19900101 ;
        time:begin_time = 0 ;
        time:fullpath = "TIME:EOSGRID" ;
        time:long_name = "time" ;
        time:standard_name = "time" ;
        time:time_increment = 60000 ;
        time:units = "seconds since 1970-01-01 00:00:00" ;
        time:cell_methods = "time: mean time: mean" ;

// global attributes:
        :nco_openmp_thread_number = 1 ;
        :Conventions = "CF-1.4" ;
        :start_time = "1990-01-01T00:00:00Z" ;
        :end_time = "1990-01-31T23:59:59Z" ;
        :history = "Fri Oct 16 17:23:11 2015: ncatted -a valid_range,,d,, -O -o timeAvgMap.MAIMNPANA_5_2_0_H.850hPa.19900101-19900131.175E_22S_175W_15S.nc timeAvgMap.MAIMNPANA_5_2_0_H.850hPa.19900101-19900131.175E_22S_175W_15S.nc\n",
            "Fri Oct 16 17:23:11 2015: ncatted -O -a title,global,o,c,MAIMNPANA_5_2_0_H Averaged over 1990-01-01 to 1990-01-31 timeAvgMap.MAIMNPANA_5_2_0_H.850hPa.19900101-19900131.175E_22S_175W_15S.nc\n",
            "Fri Oct 16 17:23:11 2015: ncks -x -v time -o timeAvgMap.MAIMNPANA_5_2_0_H.850hPa.19900101-19900131.175E_22S_175W_15S.nc -O timeAvgMap.MAIMNPANA_5_2_0_H.850hPa.19900101-19900131.175E_22S_175W_15S.nc\n",
            "Fri Oct 16 17:23:11 2015: ncwa -o timeAvgMap.MAIMNPANA_5_2_0_H.850hPa.19900101-19900131.175E_22S_175W_15S.nc -a time -O timeAvgMap.MAIMNPANA_5_2_0_H.850hPa.19900101-19900131.175E_22S_175W_15S.nc\n",
            "Fri Oct 16 17:23:11 2015: ncra -D 2 -H -O -o timeAvgMap.MAIMNPANA_5_2_0_H.850hPa.19900101-19900131.175E_22S_175W_15S.nc -d lat,-22.221700,-15.014600 -d lon,175.693400,-175.517600 -d Height,850.000000,850.000000" ;
        :NCO = "4.4.4" ;
        :title = "Time Averaged Map of Geopotential Height monthly 0.5 x 0.667 deg. @850hPa [MERRA Model MAIMNPANA v5.2.0] m over 1990-Jan, Region 175.6934E, 22.2217S, 175.5176W, 15.0146S " ;
        :userstartdate = "1990-01-01T00:00:00Z" ;
        :userenddate = "1990-01-31T23:59:59Z" ;
        :plot_hint_title = "Time Averaged Map of Geopotential Height monthly 0.5 x 0.667 deg. @850hPa [MERRA Model MAIMNPANA v5.2.0] m" ;
        :plot_hint_subtitle = "over 1990-Jan, Region 175.6934E, 22.2217S, 175.5176W, 15.0146S " ;
data:

 Height = 850 ;

 MAIMNPANA_5_2_0_H =
  1494.128, 1494.878, 1495.628, 1496.378, 1497.378, 1498.128, 1499.128, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 1491.378,
    1491.628, 1491.878, 1492.378, 1492.878, 1493.378,
  1492.628, 1493.128, 1494.128, 1494.878, 1495.878, 1496.878, 1498.128, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 1489.503,
    1489.753, 1490.128, 1490.628, 1491.128, 1491.878,
  1490.878, 1491.628, 1492.628, 1493.378, 1494.628, 1495.628, 1496.878, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 1487.753,
    1488.003, 1488.503, 1489.128, 1489.628, 1490.378,
  1489.503, 1490.128, 1491.128, 1491.878, 1493.378, 1494.378, 1495.628, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 1485.878,
    1486.253, 1486.753, 1487.378, 1488.003, 1488.753,
  1487.878, 1488.628, 1489.628, 1490.628, 1491.878, 1493.128, 1494.128, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 1484.253,
    1484.628, 1485.253, 1485.878, 1486.503, 1487.128,
  1486.378, 1487.128, 1488.128, 1489.253, 1490.378, 1491.628, 1492.878, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 1482.628,
    1483.003, 1483.503, 1484.128, 1485.003, 1485.628,
  1484.878, 1485.628, 1486.753, 1487.878, 1489.128, 1490.378, 1491.378, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 1481.128,
    1481.378, 1482.128, 1483.003, 1483.753, 1484.128,
  1483.503, 1484.253, 1485.378, 1486.628, 1487.753, 1488.878, 1490.003, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 1479.503,
    1480.003, 1480.503, 1480.503, 1482.128, 1482.753,
  1482.003, 1483.003, 1484.003, 1485.253, 1486.378, 1487.628, 1488.878, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 1477.878,
    1478.878, 1478.503, 1480.753, 1480.628, 1481.503,
  1480.753, 1481.753, 1482.753, 1484.003, 1485.253, 1486.503, 1487.753, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 1476.503,
    1477.378, 1477.253, 1479.128, 1479.253, 1480.378,
  1479.628, 1480.503, 1481.753, 1482.753, 1484.128, 1485.378, 1486.503, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 1475.503,
    1475.753, 1476.378, 1477.128, 1478.253, 1478.753,
  1478.878, 1479.503, 1480.753, 1481.628, 1482.878, 1484.128, 1485.378, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 1474.503,
    1474.628, 1475.378, 1476.128, 1477.128, 1478.128,
  1477.753, 1478.628, 1479.628, 1480.503, 1481.753, 1483.003, 1484.253, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 1473.753,
    1474.003, 1474.503, 1475.253, 1476.128, 1476.878,
  1476.878, 1477.628, 1478.503, 1479.378, 1480.503, 1481.753, 1483.003, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _,
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, 1473.003,
    1473.253, 1473.753, 1474.503, 1475.253, 1476.003 ;

 lat = -22, -21.5, -21, -20.5, -20, -19.5, -19, -18.5, -18, -17.5, -17,
    -16.5, -16, -15.5 ;

 lon = -180, -179.333333333333, -178.666666666667, -178, -177.333333333333,
    -176.666666666667, -176, -175.333333333333, -174.666666666667, -174,
    -173.333333333333, -172.666666666667, -172, -171.333333333333,
    -170.666666666667, -170, -169.333333333333, -168.666666666667, -168,
    -167.333333333333, -166.666666666667, -166, -165.333333333333,
    -164.666666666667, -164, -163.333333333333, -162.666666666667, -162,
    -161.333333333333, -160.666666666667, -160, -159.333333333333,
    -158.666666666667, -158, -157.333333333333, -156.666666666667, -156,
    -155.333333333333, -154.666666666667, -154, -153.333333333333,
    -152.666666666667, -152, -151.333333333333, -150.666666666667, -150,
    -149.333333333333, -148.666666666667, -148, -147.333333333333,
    -146.666666666667, -146, -145.333333333333, -144.666666666667, -144,
    -143.333333333333, -142.666666666667, -142, -141.333333333333,
    -140.666666666667, -140, -139.333333333333, -138.666666666667, -138,
    -137.333333333333, -136.666666666667, -136, -135.333333333333,
    -134.666666666667, -134, -133.333333333333, -132.666666666667, -132,
    -131.333333333333, -130.666666666667, -130, -129.333333333333,
    -128.666666666667, -128, -127.333333333333, -126.666666666667, -126,
    -125.333333333333, -124.666666666667, -124, -123.333333333333,
    -122.666666666667, -122, -121.333333333333, -120.666666666667, -120,
    -119.333333333333, -118.666666666667, -118, -117.333333333333,
    -116.666666666667, -116, -115.333333333333, -114.666666666667, -114,
    -113.333333333333, -112.666666666667, -112, -111.333333333333,
    -110.666666666667, -110, -109.333333333333, -108.666666666667, -108,
    -107.333333333333, -106.666666666667, -106, -105.333333333333,
    -104.666666666667, -104, -103.333333333333, -102.666666666667, -102,
    -101.333333333333, -100.666666666667, -100, -99.3333333333333,
    -98.6666666666667, -98, -97.3333333333333, -96.6666666666667, -96,
    -95.3333333333333, -94.6666666666667, -94, -93.3333333333333,
    -92.6666666666667, -92, -91.3333333333333, -90.6666666666667, -90,
    -89.3333333333333, -88.6666666666667, -88, -87.3333333333333,
    -86.6666666666667, -86, -85.3333333333333, -84.6666666666667, -84,
    -83.3333333333333, -82.6666666666667, -82, -81.3333333333333,
    -80.6666666666667, -80, -79.3333333333333, -78.6666666666667, -78,
    -77.3333333333333, -76.6666666666667, -76, -75.3333333333333,
    -74.6666666666667, -74, -73.3333333333333, -72.6666666666667, -72,
    -71.3333333333333, -70.6666666666667, -70, -69.3333333333333,
    -68.6666666666667, -68, -67.3333333333333, -66.6666666666667, -66,
    -65.3333333333333, -64.6666666666667, -64, -63.3333333333333,
    -62.6666666666667, -62, -61.3333333333333, -60.6666666666667, -60,
    -59.3333333333333, -58.6666666666667, -58, -57.3333333333333,
    -56.6666666666667, -56, -55.3333333333333, -54.6666666666667, -54,
    -53.3333333333333, -52.6666666666667, -52, -51.3333333333333,
    -50.6666666666667, -50, -49.3333333333333, -48.6666666666667, -48,
    -47.3333333333333, -46.6666666666667, -46, -45.3333333333333,
    -44.6666666666667, -44, -43.3333333333333, -42.6666666666667, -42,
    -41.3333333333333, -40.6666666666667, -40, -39.3333333333333,
    -38.6666666666667, -38, -37.3333333333333, -36.6666666666667, -36,
    -35.3333333333333, -34.6666666666667, -34, -33.3333333333333,
    -32.6666666666667, -32, -31.3333333333333, -30.6666666666667, -30,
    -29.3333333333333, -28.6666666666667, -28, -27.3333333333333,
    -26.6666666666667, -26, -25.3333333333333, -24.6666666666667, -24,
    -23.3333333333333, -22.6666666666667, -22, -21.3333333333333,
    -20.6666666666667, -20, -19.3333333333333, -18.6666666666667, -18,
    -17.3333333333333, -16.6666666666667, -16, -15.3333333333333,
    -14.6666666666667, -14, -13.3333333333333, -12.6666666666667, -12,
    -11.3333333333333, -10.6666666666667, -10, -9.33333333333334,
    -8.66666666666669, -8, -7.33333333333334, -6.66666666666669, -6,
    -5.33333333333334, -4.66666666666669, -4, -3.33333333333334,
    -2.66666666666669, -2, -1.33333333333334, -0.666666666666686, 0,
    0.666666666666657, 1.33333333333331, 2, 2.66666666666666,
    3.33333333333331, 4, 4.66666666666666, 5.33333333333331, 6,
    6.66666666666666, 7.33333333333331, 8, 8.66666666666666,
    9.33333333333331, 10, 10.6666666666667, 11.3333333333333, 12,
    12.6666666666667, 13.3333333333333, 14, 14.6666666666667,
    15.3333333333333, 16, 16.6666666666667, 17.3333333333333, 18,
    18.6666666666667, 19.3333333333333, 20, 20.6666666666667,
    21.3333333333333, 22, 22.6666666666667, 23.3333333333333, 24,
    24.6666666666667, 25.3333333333333, 26, 26.6666666666667,
    27.3333333333333, 28, 28.6666666666667, 29.3333333333333, 30,
    30.6666666666667, 31.3333333333333, 32, 32.6666666666667,
    33.3333333333333, 34, 34.6666666666667, 35.3333333333333, 36,
    36.6666666666667, 37.3333333333333, 38, 38.6666666666667,
    39.3333333333333, 40, 40.6666666666667, 41.3333333333333, 42,
    42.6666666666667, 43.3333333333333, 44, 44.6666666666667,
    45.3333333333333, 46, 46.6666666666667, 47.3333333333333, 48,
    48.6666666666667, 49.3333333333333, 50, 50.6666666666667,
    51.3333333333333, 52, 52.6666666666667, 53.3333333333333, 54,
    54.6666666666667, 55.3333333333333, 56, 56.6666666666667,
    57.3333333333333, 58, 58.6666666666667, 59.3333333333333, 60,
    60.6666666666667, 61.3333333333333, 62, 62.6666666666667,
    63.3333333333333, 64, 64.6666666666667, 65.3333333333333, 66,
    66.6666666666667, 67.3333333333333, 68, 68.6666666666667,
    69.3333333333333, 70, 70.6666666666667, 71.3333333333333, 72,
    72.6666666666667, 73.3333333333333, 74, 74.6666666666667,
    75.3333333333333, 76, 76.6666666666666, 77.3333333333333, 78,
    78.6666666666666, 79.3333333333333, 80, 80.6666666666666,
    81.3333333333333, 82, 82.6666666666666, 83.3333333333333, 84,
    84.6666666666666, 85.3333333333333, 86, 86.6666666666666,
    87.3333333333333, 88, 88.6666666666666, 89.3333333333333, 90,
    90.6666666666666, 91.3333333333333, 92, 92.6666666666666,
    93.3333333333333, 94, 94.6666666666666, 95.3333333333333, 96,
    96.6666666666666, 97.3333333333333, 98, 98.6666666666666,
    99.3333333333333, 100, 100.666666666667, 101.333333333333, 102,
    102.666666666667, 103.333333333333, 104, 104.666666666667,
    105.333333333333, 106, 106.666666666667, 107.333333333333, 108,
    108.666666666667, 109.333333333333, 110, 110.666666666667,
    111.333333333333, 112, 112.666666666667, 113.333333333333, 114,
    114.666666666667, 115.333333333333, 116, 116.666666666667,
    117.333333333333, 118, 118.666666666667, 119.333333333333, 120,
    120.666666666667, 121.333333333333, 122, 122.666666666667,
    123.333333333333, 124, 124.666666666667, 125.333333333333, 126,
    126.666666666667, 127.333333333333, 128, 128.666666666667,
    129.333333333333, 130, 130.666666666667, 131.333333333333, 132,
    132.666666666667, 133.333333333333, 134, 134.666666666667,
    135.333333333333, 136, 136.666666666667, 137.333333333333, 138,
    138.666666666667, 139.333333333333, 140, 140.666666666667,
    141.333333333333, 142, 142.666666666667, 143.333333333333, 144,
    144.666666666667, 145.333333333333, 146, 146.666666666667,
    147.333333333333, 148, 148.666666666667, 149.333333333333, 150,
    150.666666666667, 151.333333333333, 152, 152.666666666667,
    153.333333333333, 154, 154.666666666667, 155.333333333333, 156,
    156.666666666667, 157.333333333333, 158, 158.666666666667,
    159.333333333333, 160, 160.666666666667, 161.333333333333, 162,
    162.666666666667, 163.333333333333, 164, 164.666666666667,
    165.333333333333, 166, 166.666666666667, 167.333333333333, 168,
    168.666666666667, 169.333333333333, 170, 170.666666666667,
    171.333333333333, 172, 172.666666666667, 173.333333333333, 174,
    174.666666666667, 175.333333333333, 176, 176.666666666667,
    177.333333333333, 178, 178.666666666667, 179.333333333333 ;

 time = 631152000 ;
}
'''
        sld_str = '''<?xml version="1.0"?>
<StyledLayerDescriptor xmlns="http://www.opengis.net/sld" xmlns:se="http://www.opengis.net/se" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.1.0" xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.1.0/StyledLayerDescriptor.xsd">
  <NamedLayer>
    <se:Name>spectral_div_11_sld</se:Name>
    <UserStyle>
      <se:Name>Spectral (Div), 11</se:Name>
      <se:FeatureTypeStyle>
        <se:Rule>
          <se:RasterSymbolizer>
            <se:Opacity>1.0</se:Opacity>
            <se:ColorMap>
              <se:Categorize fallbackValue="#ff00ff">
                <se:LookupValue>Rasterdata</se:LookupValue>
                <se:Value>#9e0142</se:Value>
                <se:Threshold>1473</se:Threshold>
                <se:Value>#d53e4f</se:Value>
                <se:Threshold>1476</se:Threshold>
                <se:Value>#f46d43</se:Value>
                <se:Threshold>1479</se:Threshold>
                <se:Value>#fdae61</se:Value>
                <se:Threshold>1482</se:Threshold>
                <se:Value>#fee08b</se:Value>
                <se:Threshold>1485</se:Threshold>
                <se:Value>#ffffbf</se:Value>
                <se:Threshold>1488</se:Threshold>
                <se:Value>#e6f598</se:Value>
                <se:Threshold>1491</se:Threshold>
                <se:Value>#abdda4</se:Value>
                <se:Threshold>1494</se:Threshold>
                <se:Value>#66c2a5</se:Value>
                <se:Threshold>1497</se:Threshold>
                <se:Value>#3288bd</se:Value>
                <se:Threshold>1500</se:Threshold>
                <se:Value>#5e4fa2</se:Value>
              </se:Categorize>
            </se:ColorMap>
          </se:RasterSymbolizer>
          <se:Name>m</se:Name>
        </se:Rule>
      </se:FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
'''
        world_file_string = """0.666667
0
0
-0.500000
-180.000000
-15.500000
"""
        self.runPlotTest(cdl, sld_str, world_file_string)

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
        self.runPlotTest(
            cdl, sld_str, world_file_string,
            'OMAERUVd_003_FinalAerosolExtOpticalDepth500')

        # make sure that the code doesn't blow up if we specify height and
        # width
        self.runPlotTest(cdl, sld_str, height=3)
        self.runPlotTest(cdl, sld_str, height=3, width=10)
        self.runPlotTest(cdl, sld_str, width=3)
        self.runPlotTest(cdl, sld_str, inflation_factor=3)

        self.runContourTest(cdl, sld_str, world_file_string)

    def testBoundingBox(self):
        cdl = """netcdf g4.timeAvgMap.OMAERUVd_003_FinalAerosolSingleScattAlb500.20060101-20060101.9E_9N_14E_13N {
dimensions:
    lat = 4 ;
    lon = 5 ;
variables:
    float OMAERUVd_003_FinalAerosolSingleScattAlb500(lat, lon) ;
        OMAERUVd_003_FinalAerosolSingleScattAlb500:_FillValue = -1.267651e+30f ;
        OMAERUVd_003_FinalAerosolSingleScattAlb500:units = "1" ;
        OMAERUVd_003_FinalAerosolSingleScattAlb500:title = "Final Aerosol Single Scattering Albedo at 500 nm" ;
        OMAERUVd_003_FinalAerosolSingleScattAlb500:UniqueFieldDefinition = "OMI-Specific" ;
        OMAERUVd_003_FinalAerosolSingleScattAlb500:missing_value = -1.267651e+30f ;
        OMAERUVd_003_FinalAerosolSingleScattAlb500:origname = "FinalAerosolSingleScattAlb500" ;
        OMAERUVd_003_FinalAerosolSingleScattAlb500:fullnamepath = "/HDFEOS/GRIDS/Aerosol NearUV Grid/Data Fields/FinalAerosolSingleScattAlb500" ;
        OMAERUVd_003_FinalAerosolSingleScattAlb500:orig_dimname_list = "XDim " ;
        OMAERUVd_003_FinalAerosolSingleScattAlb500:standard_name = "finalaerosolsinglescattalb500" ;
        OMAERUVd_003_FinalAerosolSingleScattAlb500:quantity_type = "Albedo" ;
        OMAERUVd_003_FinalAerosolSingleScattAlb500:product_short_name = "OMAERUVd" ;
        OMAERUVd_003_FinalAerosolSingleScattAlb500:product_version = "003" ;
        OMAERUVd_003_FinalAerosolSingleScattAlb500:long_name = "Aerosol Single Scattering Albedo 500 nm" ;
        OMAERUVd_003_FinalAerosolSingleScattAlb500:coordinates = "lat lon" ;
        OMAERUVd_003_FinalAerosolSingleScattAlb500:cell_methods = "time: mean time: mean" ;
        OMAERUVd_003_FinalAerosolSingleScattAlb500:latitude_resolution = 1. ;
        OMAERUVd_003_FinalAerosolSingleScattAlb500:longitude_resolution = 1. ;
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
        :start_time = "2006-01-01T00:00:00Z" ;
        :end_time = "2006-01-01T23:59:59Z" ;
        :history = "Fri Aug 21 18:44:28 2015: ncatted -a valid_range,,d,, -O -o timeAvgMap.OMAERUVd_003_FinalAerosolSingleScattAlb500.20060101-20060101.9E_9N_14E_13N.nc timeAvgMap.OMAERUVd_003_FinalAerosolSingleScattAlb500.20060101-20060101.9E_9N_14E_13N.nc\n",
            "Fri Aug 21 18:44:28 2015: ncatted -O -a title,global,o,c,OMAERUVd_003_FinalAerosolSingleScattAlb500 Averaged over 2006-01-01 to 2006-01-01 timeAvgMap.OMAERUVd_003_FinalAerosolSingleScattAlb500.20060101-20060101.9E_9N_14E_13N.nc\n",
            "Fri Aug 21 18:44:28 2015: ncks -x -v time -o timeAvgMap.OMAERUVd_003_FinalAerosolSingleScattAlb500.20060101-20060101.9E_9N_14E_13N.nc -O timeAvgMap.OMAERUVd_003_FinalAerosolSingleScattAlb500.20060101-20060101.9E_9N_14E_13N.nc\n",
            "Fri Aug 21 18:44:28 2015: ncwa -o timeAvgMap.OMAERUVd_003_FinalAerosolSingleScattAlb500.20060101-20060101.9E_9N_14E_13N.nc -a time -O timeAvgMap.OMAERUVd_003_FinalAerosolSingleScattAlb500.20060101-20060101.9E_9N_14E_13N.nc\n",
            "Fri Aug 21 18:44:28 2015: ncra -D 2 -H -O -o timeAvgMap.OMAERUVd_003_FinalAerosolSingleScattAlb500.20060101-20060101.9E_9N_14E_13N.nc -d lat,9.000000,13.000000 -d lon,9.000000,14.000000" ;
        :NCO = "4.4.4" ;
        :title = "Time Averaged Map of Aerosol Single Scattering Albedo 500 nm daily 1 deg. [OMI OMAERUVd v003] over 2006-01-01, Region 9E, 9N, 14E, 13N " ;
        :userstartdate = "2006-01-01T00:00:00Z" ;
        :userenddate = "2006-01-01T23:59:59Z" ;
        :plot_hint_title = "Time Averaged Map of Aerosol Single Scattering Albedo 500 nm daily 1 deg. [OMI OMAERUVd v003]" ;
        :plot_hint_subtitle = "over 2006-01-01, Region 9E, 9N, 14E, 13N " ;
data:

 OMAERUVd_003_FinalAerosolSingleScattAlb500 =
  0.7907, 0.8173, 0.8823, 0.8007, 0.7945,
  0.7881, 0.9583, 0.8716, 0.9101, 0.9495,
  _, _, _, 0.9613, 0.8395,
  _, _, _, _, 0.7996 ;

 lat = 9.5, 10.5, 11.5, 12.5 ;

 lon = 9.5, 10.5, 11.5, 12.5, 13.5 ;

 time = 1136073600 ;
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
                <se:Threshold>0.775</se:Threshold>
                <se:Value>#fee0d2</se:Value>
                <se:Threshold>0.807</se:Threshold>
                <se:Value>#fcbba1</se:Value>
                <se:Threshold>0.839</se:Threshold>
                <se:Value>#fc9272</se:Value>
                <se:Threshold>0.872</se:Threshold>
                <se:Value>#fb6a4a</se:Value>
                <se:Threshold>0.904</se:Threshold>
                <se:Value>#ef3b2c</se:Value>
                <se:Threshold>0.936</se:Threshold>
                <se:Value>#cb181d</se:Value>
                <se:Threshold>0.968</se:Threshold>
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
        world_file_string = """0.002933
0
0
-0.002933
10.001466
11.998534
"""
        self.runPlotTest(
            cdl, sld_str, world_file_string,
            variable_name='OMAERUVd_003_FinalAerosolSingleScattAlb500',
            south=10, north=12, west=10, east=13)

    def runSLDTest(self, sld_str, fallback_color, thresholds, hex_colors):
        sld_file = os.path.join(self.dir, 'sld.xml')
        handle = open(sld_file, 'w')
        handle.write(sld_str)
        handle.close()

        _, _, test_thresholds, test_fallback_color, test_hex_colors = \
            mp.sld_to_colormap(sld_file)

        self.assertEqual(
            fallback_color, test_fallback_color, "Fallback color correct")
        self.assertEqual(
            len(thresholds), len(test_thresholds), "Correct number of thresholds")
        for i in range(len(test_fallback_color)):
            self.assertAlmostEqual(
                thresholds[i], test_thresholds[i], 2, "Threshold %d correct" % i)
        self.assertEqual(hex_colors, test_hex_colors, "Colors correct")

    def testGreenYellow(self):
        sld_str = """<?xml version="1.0"?>
<StyledLayerDescriptor xmlns="http://www.opengis.net/sld" xmlns:se="http://www.opengis.net/se" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.1.0" xsi:schemaLocation="http://www.opengis.net/sld http://schemas.opengis.net/sld/1.1.0/StyledLayerDescriptor.xsd">
  <NamedLayer>
    <se:Name>buylrd_div_12_panoply_sld</se:Name>
    <UserStyle>
      <se:Name>Blue-Yellow-Red (Div), 12 (Source: Panoply)</se:Name>
      <se:FeatureTypeStyle>
        <se:Rule>
          <se:RasterSymbolizer>
            <se:Opacity>1.0</se:Opacity>
            <se:ColorMap>
              <se:Categorize fallbackValue="#ff00ff">
                <se:LookupValue>Rasterdata</se:LookupValue>
                <se:Value>#0000FF</se:Value>
                <se:Threshold>0</se:Threshold>
                <se:Value>#2288FF</se:Value>
                <se:Threshold>0.266</se:Threshold>
                <se:Value>#55AAFF</se:Value>
                <se:Threshold>0.533</se:Threshold>
                <se:Value>#99CCFF</se:Value>
                <se:Threshold>0.799</se:Threshold>
                <se:Value>#CCEEFF</se:Value>
                <se:Threshold>1.066</se:Threshold>
                <se:Value>#EEFFFF</se:Value>
                <se:Threshold>1.332</se:Threshold>
                <se:Value>#FFFF44</se:Value>
                <se:Threshold>1.598</se:Threshold>
                <se:Value>#FFE300</se:Value>
                <se:Threshold>1.865</se:Threshold>
                <se:Value>#FF9933</se:Value>
                <se:Threshold>2.131</se:Threshold>
                <se:Value>#FF5500</se:Value>
                <se:Threshold>2.398</se:Threshold>
                <se:Value>#FF0000</se:Value>
                <se:Threshold>2.664</se:Threshold>
                <se:Value>#DD0000</se:Value>
              </se:Categorize>
            </se:ColorMap>
          </se:RasterSymbolizer>
        </se:Rule>
      </se:FeatureTypeStyle>
    </UserStyle>
  </NamedLayer>
</StyledLayerDescriptor>
"""
        fallback_color = "#ff00ff"
        thresholds = [0.0, 0.266, 0.533, 0.799, 1.066,
                      1.332, 1.598, 1.865, 2.131, 2.398, 2.664]
        hex_colors = ["#0000FF", "#2288FF", "#55AAFF",
                      "#99CCFF", "#CCEEFF", "#EEFFFF",
                      "#FFFF44", "#FFE300", "#FF9933", "#FF5500", "#FF0000",
                      "#DD0000"]
        self.runSLDTest(sld_str, fallback_color, thresholds, hex_colors)


if __name__ == "__main__":
    unittest.main()
