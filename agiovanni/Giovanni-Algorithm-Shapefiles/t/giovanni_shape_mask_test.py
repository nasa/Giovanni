#!/usr/bin/env python
"""Tests for the giovanni_shape_mask.py script.

These tests use data in the CVS://aGiovanni/Giovanni-Algorithm/Shapefiles/
t/d/ subdirectories. Supporting libraries for giovanni_shape_mask.py
are loaded from the CVS repository relative to this file.
"""

__author__ = 'Daniel da Silva <Daniel.daSilva@nasa.gov>'
__author__ = 'Michael A Nardozzi <michael.a.nardozzi@nasa.gov>'

import os
import shutil
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

import netCDF4
import numpy

CUR_DIR = os.path.dirname(os.path.realpath(__file__))
sys.path.insert(0, os.path.join(CUR_DIR, '..', '..', 'python'))
sys.path.insert(0, os.path.join(CUR_DIR, '..', 'scripts'))
os.chdir(CUR_DIR)

import agiovanni.mfst
import giovanni_shape_mask

# Mapping of short name to shapes. Used by tests to refer to specific
# shapes whose ID may change in the future if shapefiles are exchanged.
SHAPE_SHORT_NAMES = {
    # Countries
    'brazil': 'state_dept_countries/shp_32',
    'united_states': 'state_dept_countries/shp_232',

    # States
    'alaska': 'tl_2014_us_state/shp_40',
    'california': 'tl_2014_us_state/shp_13',
    'maryland': 'tl_2014_us_state/shp_4',
    'ohio': 'tl_2014_us_state/shp_25',
    'texas': 'tl_2014_us_state/shp_25',
    'west_virginia': 'tl_2014_us_state/shp_0',

    # Land/Sea Masks
    'gpmLandMask': 'gpmLandMask/shp_0',  
    'gpmSeaMask': 'gpmSeaMask/shp_0',
}

# Directory that shapesfiles reside 
SHAPES_DIR = '/var/giovanni/shapefiles'


class ConfigEnvMock(object):
    """Mock agiovanni.cfg.ConfigEnvironment class"""
    AATS_DS_VAR_NAME = '$GIOVANNI::SHAPEFILES{down_sampling}{area_avg_time_series}'
    SHAPE_PROV_DIR = '$GIOVANNI::SHAPEFILES{provisioned_dir}'

    def __init__(self, config_vars={}):
        self.config_vars = config_vars
        self.get = config_vars.get
        
        if self.SHAPE_PROV_DIR not in self.config_vars:
            self.config_vars[self.SHAPE_PROV_DIR] = SHAPES_DIR

        if self.AATS_DS_VAR_NAME not in self.config_vars:
            self.config_vars[self.AATS_DS_VAR_NAME] = '4.0'

    def getAATSDownSamplingFactor(self):
        return float(self.config_vars.get(self.AATS_DS_VAR_NAME))
        
    def getShapeFileProvisionedDir(self):
        return self.config_vars.get(self.SHAPE_PROV_DIR)


class ModeTest(unittest.TestCase):
    """Base class for mode tests."""

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        os.chdir(self.temp_dir)
        _, self.in_file = tempfile.mkstemp()
        _, self.out_file = tempfile.mkstemp(prefix='mfst.')
        self.prov_file = self.out_file.replace('mfst.', 'prov.')
        
    def tearDown(self):
        shutil.rmtree(self.temp_dir)
        os.remove(self.in_file)
        os.remove(self.out_file)

        if os.path.exists(self.prov_file):
            os.remove(self.prov_file)
        
    def get_files(self, data_dir):
        """Get list of paths of NetCDF files in t/d/$data_dir."""
        dir_path = os.path.join(CUR_DIR, 'd', data_dir)
        fpaths = []
        for fname in os.listdir(dir_path):
            if fname.endswith('.nc'):
                fpath = os.path.join(CUR_DIR, 'd', data_dir, fname)
                fpaths.append(fpath)
                
        return fpaths

    def get_var_name(self, input_file):
        """Find variable with 3 or 4 dimensions in NetCDF file."""
        dataset = netCDF4.Dataset(input_file)
        ret = None

        for var_name, var in dataset.variables.iteritems():
            if len(var.shape) in (3, 4):
                ret = var_name
                break
                
        dataset.close()
                
        if ret is None:
            raise RuntimeError("Could not find var with 3 or 4 dims in %s"
                               % input_file)
        return ret

    def do_data_and_shape(self, data_dir, shape_name):
        """Tests the script in area average mode with given data and shape.
        
        Tests performed:
        - mask exists in each data file
        - science variable exists in each data file
        - for each data file, the contained mask has only values in [0, 1]
        """
        # Execution Phase ------------------------------------------------
        in_files = self.get_files(data_dir)
        var_name = self.get_var_name(in_files[0])

        agiovanni.mfst.write_file_list(self.in_file, var_name, in_files)

        argv = [
            giovanni_shape_mask.__name__,
            '--in-file', self.in_file,
            '--out-file', self.out_file,            
            '-S', SHAPE_SHORT_NAMES[shape_name],
            '--service', self.SERVICE,
            '--silent',
        ]
        
        giovanni_shape_mask.main(argv=argv, config_env=ConfigEnvMock())

        # Assertion Phase ------------------------------------------------

        assert os.path.exists(self.prov_file)
        prov_root = ET.parse(self.prov_file).getroot()
        prov_inputs = prov_root.find('inputs').findall('input')
        prov_outputs = prov_root.find('outputs').findall('output')
        assert len(prov_inputs) > 0
        assert len(prov_outputs) > 0
        for input_node in prov_inputs:
            assert os.path.exists(input_node.text)
        for output_node in prov_outputs:
            assert os.path.exists(output_node.text)

        var_id, out_files = agiovanni.mfst.read_file_list(self.out_file)
        mask_id = giovanni_shape_mask.MASK_VAR_NAME
        self.assertEqual(len(prov_outputs) - 2, len(out_files))
        
        # Get grid from a sample input file to compare against the
        # output files.
        input_dataset = netCDF4.Dataset(in_files[0])
        input_lat = input_dataset.variables['lat'][:]
        input_lon = input_dataset.variables['lon'][:]
        input_dataset.close()

        for out_file in out_files:
            dataset = netCDF4.Dataset(out_file)
            
            # Assert that the file contains variables for both the mask
            # and the scientific variable.
            self.assertTrue(mask_id in dataset.variables)
            self.assertTrue(var_id in dataset.variables)

            mask = dataset.variables[mask_id][:]
            var = dataset.variables[var_id][:]

            # Assert that the variable for the mask only contains values
            # in the interval [0, 1].
            self.assertTrue(mask.min() >= 0, 'mask.min() is %s' % repr(mask.min()))
            self.assertTrue(mask.max() <= 1, 'mask.max() is %s' % repr(mask.max()))

            # Assert that the file is on the same grid as the input data
            lat = dataset.variables['lat'][:]
            lon = dataset.variables['lon'][:]

            self.assertTrue(set(lat).issubset(set(input_lat)))
            self.assertTrue(set(lon).issubset(set(input_lon)))

            # Call method subclasses can define that adds extra assertions
            self.extra_assertions(mask, var)
            
            dataset.close()


    def extra_assertions(self, mask, var):
        """Method to override to add extra assertions."""


class AreaAverageModeTest(ModeTest):
    """Tests for the AreaAverageMode class."""
    SERVICE = 'ArAvTs'
        
    def test_AIRX3STD_v006_maryland(self):
        self.do_data_and_shape('AIRX3STD_v006', 'maryland')

    def test_AIRX3STD_v006_texas(self):
        self.do_data_and_shape('AIRX3STD_v006', 'texas')  

    def test_GLDAS_NOAH10_M_v020_california(self):
        self.do_data_and_shape('GLDAS_NOAH10_M_v020', 'california')  
    
    def test_GLDAS_NOAH10_M_v001_california(self):
        self.do_data_and_shape('GLDAS_NOAH10_M_v001', 'california')  

    def test_NLDAS_FORA0125_H_v002_brazil(self):
        self.do_data_and_shape('NLDAS_FORA0125_H_v002', 'united_states')

    def test_NLDAS_FORA0125_H_v002_united_states(self):
        self.do_data_and_shape('NLDAS_FORA0125_H_v002', 'united_states')

    def test_NLDAS_FORA0125_H_v002_west_virginia(self):
        self.do_data_and_shape('NLDAS_FORA0125_H_v002', 'west_virginia')

    def test_AIRX3STD_v006_gpmLandMask(self): # Test for regrid to lower resolution (down sampling) 
        self.do_data_and_shape('AIRX3STD_v006', 'gpmLandMask')

    def test_GPM_3IMERGHH_03_gpmSeaMask(self): # Test for regrid to same resolution
        self.do_data_and_shape('GPM_3IMERGHH_03', 'gpmSeaMask')

    def test_SWDB_L3M10_v004_united_states(self):
        self.do_data_and_shape('SWDB_L3M10_v004', 'united_states')

    def test_SWDB_L3M10_v004_ohio(self):
        self.do_data_and_shape('SWDB_L3M10_v004', 'ohio')

    def test_TRMM_3B42_v7_maryland(self):
        self.do_data_and_shape('TRMM_3B42_v7', 'maryland')

    def test_TRMM_3B42_v7_texas(self):
        self.do_data_and_shape('TRMM_3B42_v7', 'texas')


class DefaultModeTest(ModeTest):
    """Tests for the AreaAverageMode class."""
    SERVICE = 'HISTOGRAM'

    def extra_assertions(self, mask, var):
        # Assert that whenever the variable is unmasked,
        # the mask allows it to be.
        m = var.mask
        v = numpy.logical_not(mask)
        self.assertFalse((v & ~m).any())
        
    def test_AIRX3STD_v006_alaska(self):
        self.do_data_and_shape('AIRX3STD_v006', 'alaska')
        
    def test_AIRX3STD_v006_maryland(self):
        self.do_data_and_shape('AIRX3STD_v006', 'maryland')

    def test_AIRX3STD_v006_texas(self):
        self.do_data_and_shape('AIRX3STD_v006', 'texas')  
    
    def test_GLDAS_NOAH10_M_v020_california(self):
        self.do_data_and_shape('GLDAS_NOAH10_M_v020', 'california')  

    def test_GLDAS_NOAH10_M_v001_california(self):
        self.do_data_and_shape('GLDAS_NOAH10_M_v001', 'california')  

    def test_NLDAS_FORA0125_H_v002_brazil(self):
        self.do_data_and_shape('NLDAS_FORA0125_H_v002', 'united_states')

    def test_NLDAS_FORA0125_H_v002_united_states(self):
        self.do_data_and_shape('NLDAS_FORA0125_H_v002', 'united_states')

    def test_NLDAS_FORA0125_H_v002_west_virginia(self):
        self.do_data_and_shape('NLDAS_FORA0125_H_v002', 'west_virginia')

    def test_AIRX3STD_v006_gpmLandMask(self): # Test for regrid to lower resolution (down sampling)
        self.do_data_and_shape('AIRX3STD_v006', 'gpmLandMask')

    def test_GPM_3IMERGHH_03_gpmSeaMask(self): # Test for regrid to same resolution
        self.do_data_and_shape('GPM_3IMERGHH_03', 'gpmSeaMask')

    def test_SWDB_L3M10_v004_united_states(self):
        self.do_data_and_shape('SWDB_L3M10_v004', 'united_states')

    def test_SWDB_L3M10_v004_ohio(self):
        self.do_data_and_shape('SWDB_L3M10_v004', 'ohio')

    def test_TRMM_3B42_v7_maryland(self):
        self.do_data_and_shape('TRMM_3B42_v7', 'maryland')

    def test_TRMM_3B42_v7_texas(self):
        self.do_data_and_shape('TRMM_3B42_v7', 'texas')        


class TestNoShapeOption(unittest.TestCase):
    """Tests that the script when no -S option is provided."""

    def setUp(self):
        _, self.in_file = tempfile.mkstemp()
        _, self.out_file = tempfile.mkstemp()

    def tearDown(self):
        os.remove(self.in_file)
        os.remove(self.out_file)

    def test_no_S_option(self):
        # Write input file
        agiovanni.mfst.write_file_list(self.in_file, 'var_name', [
            '/tmp/file01.nc',
            '/tmp/file02.nc',
            '/tmp/file03.nc',
        ])

        # Call main without a -S option
        argv = [
            giovanni_shape_mask.__name__,
            '--in-file', self.in_file,
            '--out-file', self.out_file,            
            '--service', 'ArAvTs',
        ]
        
        giovanni_shape_mask.main(argv=argv, config_env=ConfigEnvMock())

        # Verify the input file and output file have the same
        # contents. It should be permissible for them to XML-equal
        # but not string-equal (due to whitespace, attribute ordering,
        # etc) but for simplicity we test for string-equality here.
        in_file_contents = open(self.in_file).read()
        out_file_contents = open(self.out_file).read()
        
        self.assertEqual(in_file_contents, out_file_contents)


if __name__ == '__main__':
    unittest.main()
    
