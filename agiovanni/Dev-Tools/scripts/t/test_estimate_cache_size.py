
__author__ = "Christine Smit <christine.e.smit@nasa.gov>"

import unittest
import tempfile
import shutil
import StringIO
import os
import datetime as dt

import estimate_cache_size as ecs


class Test(unittest.TestCase):

    def setUp(self):
        self.dir = tempfile.mkdtemp()
        self.varInfo = {}
        self.varSize = {}
        self.aesirLocation = 'https://aesir.gsfc.nasa.gov/aesir_solr/TS1'
        self.giovanniLocation = 'http://giovanni.gsfc.nasa.gov/giovanni/'

    def tearDown(self):
        shutil.rmtree(self.dir)

    def getCatalogInfo(self, aesir_location, var_id):
        return self.varInfo[var_id]

    def getFileSize(self, base_url, start_time, end_time, var_id, logger):
        return self.varSize[var_id]

    def runSingleTest(self, var_id, correctEstimate,
                      getCatalogInfo=None, getFileSize=None):
        outputStream = StringIO.StringIO()
        inputFile = os.path.join(self.dir, "input.txt")
        handle = open(inputFile, "w")
        handle.write("%s\n" % var_id)
        handle.close()

        argv = [self.aesirLocation, self.giovanniLocation,
                inputFile]

        if getCatalogInfo is None:
            getCatalogInfo = ecs.get_catalog_info

        if getFileSize is None:
            getFileSize = ecs.get_file_size

        ecs.main(
            argv, outputStream, getCatalogInfo, getFileSize)

        out = outputStream.getvalue()
        outAsFloat = float(out.strip())
        self.assertAlmostEquals(
            outAsFloat, correctEstimate, 1,
            "Got the correct size. Expected %f, got %f." % (outAsFloat,
                                                            correctEstimate))

    def testFull(self):
        '''
        Tests everything - going to AESIR, downloading a sample file, and
        calculating the size. So it's really more of an integration test and will
        fail if AESIR information changes.
        '''

        fileSize = 11655457
        numSlices = 160
        correctEstimate = fileSize * numSlices / (1000 * 1000.0)
        # Pick a seawifs variable because the seawifs mission ended and there
        # won't be any new granules.
        self.runSingleTest(
            'SeaWiFS_L3m_IOP_2014_adg_443_giop', correctEstimate, None, None)

    def testFullNotThere(self):

        self.runSingleTest('Nonsense_variable', 0, None, None)

    def testGetScrubbedUrls(self):
        xml_string = """<?xml version="1.0"?>
<provenance ELAPSED_TIME="7.29">
  <group name="data_field_info" ELAPSED_TIME="0.12">
    <step ELAPSED_TIME="0.120481" NAME="Data Catalog Query">
      <outputs>
        <output NAME="Metadata from data catalog" TYPE="URL" LABEL="mfst.data_field_info+dTRMM_3B42_daily_precipitation_V6.xml">http://giovanni.gsfc.nasa.gov/session//CC3DEFAC-3D1C-11E5-B859-3547CE2E0106/CC41C32A-3D1C-11E5-B859-3547CE2E0106/CC42FA6A-3D1C-11E5-B859-3547CE2E0106/mfst.data_field_info+dTRMM_3B42_daily_precipitation_V6.xml</output>
      </outputs>
      <messages/>
    </step>
  </group>
  <group name="data_search" ELAPSED_TIME="1.84">
    <step ELAPSED_TIME="1.842383" NAME="Search for data">
      <outputs>
        <output NAME="Data URL" TYPE="URL">http://disc2.nascom.nasa.gov/daac-bin/OTF/HTTP_services.cgi?FILENAME=%2Fftp%2Fdata%2Fs4pa%2FTRMM_L3%2FTRMM_3B42_daily.6%2F1997%2F365%2F3B42_daily.1998.01.01.6.bin&amp;FORMAT=bmV0Q0RGLw&amp;LABEL=3B42_daily.1998.01.01.6.nc&amp;SHORTNAME=TRMM_3B42_daily&amp;SERVICE=HDF_TO_NetCDF&amp;VERSION=1.02&amp;DATASET_VERSION=6&amp;VARIABLES=TRMM_3B42_daily_precipitation_V6</output>
        <output NAME="Data URL" TYPE="URL">http://disc2.nascom.nasa.gov/daac-bin/OTF/HTTP_services.cgi?FILENAME=%2Fftp%2Fdata%2Fs4pa%2FTRMM_L3%2FTRMM_3B42_daily.6%2F1998%2F001%2F3B42_daily.1998.01.02.6.bin&amp;FORMAT=bmV0Q0RGLw&amp;LABEL=3B42_daily.1998.01.02.6.nc&amp;SHORTNAME=TRMM_3B42_daily&amp;SERVICE=HDF_TO_NetCDF&amp;VERSION=1.02&amp;DATASET_VERSION=6&amp;VARIABLES=TRMM_3B42_daily_precipitation_V6</output>
      </outputs>
      <messages/>
    </step>
  </group>
  <group name="data_fetch" ELAPSED_TIME="0.04">
    <step ELAPSED_TIME="0.036189" NAME="Data Staging">
      <outputs>
        <output NAME="Output file" TYPE="URL" LABEL="scrubbed.TRMM_3B42_daily_precipitation_V6.19980101.nc">http://giovanni.gsfc.nasa.gov/session//CC3DEFAC-3D1C-11E5-B859-3547CE2E0106/CC41C32A-3D1C-11E5-B859-3547CE2E0106/CC42FA6A-3D1C-11E5-B859-3547CE2E0106///scrubbed.TRMM_3B42_daily_precipitation_V6.19980101.nc</output>
        <output NAME="Output file" TYPE="URL" LABEL="scrubbed.TRMM_3B42_daily_precipitation_V6.19980102.nc">http://giovanni.gsfc.nasa.gov/session//CC3DEFAC-3D1C-11E5-B859-3547CE2E0106/CC41C32A-3D1C-11E5-B859-3547CE2E0106/CC42FA6A-3D1C-11E5-B859-3547CE2E0106///scrubbed.TRMM_3B42_daily_precipitation_V6.19980102.nc</output>
      </outputs>
      <messages/>
    </step>
  </group>
  <group name="result+sTmAvMp" ELAPSED_TIME="5.15">
    <step ELAPSED_TIME="5.151703" NAME="Time Averaged Map">
      <outputs>
        <output NAME="file" TYPE="URL" LABEL="timeAvgMap.TRMM_3B42_daily_precipitation_V6.19980101-19980102.180W_50S_180E_50N.nc">http://giovanni.gsfc.nasa.gov/session//CC3DEFAC-3D1C-11E5-B859-3547CE2E0106/CC41C32A-3D1C-11E5-B859-3547CE2E0106/CC42FA6A-3D1C-11E5-B859-3547CE2E0106/timeAvgMap.TRMM_3B42_daily_precipitation_V6.19980101-19980102.180W_50S_180E_50N.nc</output>
      </outputs>
      <messages/>
    </step>
  </group>
  <group name="postprocess+sTmAvMp" ELAPSED_TIME="0.14">
    <step ELAPSED_TIME="0.136045" NAME="Post-Processing">
      <outputs>
        <output NAME="file" TYPE="URL" LABEL="g4.timeAvgMap.TRMM_3B42_daily_precipitation_V6.19980101-19980102.180W_50S_180E_50N.nc">http://giovanni.gsfc.nasa.gov/session//CC3DEFAC-3D1C-11E5-B859-3547CE2E0106/CC41C32A-3D1C-11E5-B859-3547CE2E0106/CC42FA6A-3D1C-11E5-B859-3547CE2E0106/g4.timeAvgMap.TRMM_3B42_daily_precipitation_V6.19980101-19980102.180W_50S_180E_50N.nc</output>
      </outputs>
      <messages/>
    </step>
  </group>
</provenance>
"""

        # write the XML to a file
        xml_file = os.path.join(self.dir, "lineage.xml")
        handle = open(xml_file, "w")
        handle.write(xml_string)
        handle.close()

        correctScrubbedUrls = ['http://giovanni.gsfc.nasa.gov/session//CC3DEFAC-3D1C-11E5-B859-3547CE2E0106/CC41C32A-3D1C-11E5-B859-3547CE2E0106/CC42FA6A-3D1C-11E5-B859-3547CE2E0106///scrubbed.TRMM_3B42_daily_precipitation_V6.19980101.nc',
                               'http://giovanni.gsfc.nasa.gov/session//CC3DEFAC-3D1C-11E5-B859-3547CE2E0106/CC41C32A-3D1C-11E5-B859-3547CE2E0106/CC42FA6A-3D1C-11E5-B859-3547CE2E0106///scrubbed.TRMM_3B42_daily_precipitation_V6.19980102.nc']

        scrubbedUrls = ecs.get_scrubbed_urls(xml_file)
        self.assertEqual(
            correctScrubbedUrls, scrubbedUrls, "Got the correct urls")

    def testGetNumSlices(self):
        str2DT = lambda x: dt.datetime.strptime(x, '%Y-%m-%dT%H:%M:%SZ')

        # monthly
        self.assertEqual(
            ecs.get_num_slices(
                start_date_time=str2DT('2000-02-01T00:00:00Z'),
                end_date_time=str2DT(
                    '2003-12-31T23:59:59Z'),
                temporal_resolution='monthly',
                today=str2DT('2015-09-05T04:25:04Z')),
            47, 'monthly calculation correct')

        # daily
        self.assertEqual(
            ecs.get_num_slices(
                start_date_time=str2DT('2004-10-01T00:00:00Z'),
                end_date_time=str2DT(
                    '2010-12-31T23:59:59Z'),
                temporal_resolution='daily',
                today=str2DT('2015-09-05T04:25:04Z')),
            2283, 'daily calculation correct')

        # 3-hourly
        self.assertEqual(
            ecs.get_num_slices(
                start_date_time=str2DT('2004-10-01T00:00:00Z'),
                end_date_time=str2DT(
                    '2010-12-31T23:59:59Z'),
                temporal_resolution='3-hourly',
                today=str2DT('2015-09-05T04:25:04Z')),
            2283 * 8, '3-hourly calculation correct')

        # hourly
        self.assertEqual(
            ecs.get_num_slices(
                start_date_time=str2DT('2004-10-01T00:00:00Z'),
                end_date_time=str2DT(
                    '2010-12-31T23:59:59Z'),
                temporal_resolution='hourly',
                today=str2DT('2015-09-05T04:25:04Z')),
            2283 * 24, 'hourly calculation correct')

        # half-hourly
        self.assertEqual(
            ecs.get_num_slices(
                start_date_time=str2DT('2004-10-01T00:00:00Z'),
                end_date_time=str2DT(
                    '2010-12-31T23:59:59Z'),
                temporal_resolution='half-hourly',
                today=str2DT('2015-09-05T04:25:04Z')),
            2283 * 24 * 2, 'half-hourly calculation correct')

        # test that if the end date is after the current time, we only calculate
        # slices up to the current time
        # daily
        self.assertEqual(
            ecs.get_num_slices(
                start_date_time=str2DT('2004-10-01T00:00:00Z'),
                end_date_time=str2DT(
                    '2030-12-31T23:59:59Z'),
                temporal_resolution='daily',
                today=str2DT('2010-12-31T23:59:59Z')),
            2283, 'daily calculation correct when end date is after current time')

    def testBasic(self):
        varId = "OMTO3e_003_ColumnAmountO3"
        # http://aesir.gesdisc.eosdis.nasa.gov/aesir_solr/TS2//select/?q=*&fq=dataFieldId:%22OMTO3e_003_ColumnAmountO3%22&wt=json
        self.varInfo[varId] = r"""{
  "responseHeader": {
    "status": 0,
    "QTime": 1,
    "params": {
      "q": "*",
      "wt": "json",
      "fq": "dataFieldId:\"OMTO3e_003_ColumnAmountO3\""
    }
  },
  "response": {
    "numFound": 1,
    "start": 0,
    "docs": [
      {
        "dataFieldId": "OMTO3e_003_ColumnAmountO3",
        "dataFieldG3Id": "OMTO3e_003_ColumnAmountO3",
        "dataFieldActive": true,
        "dataFieldSdsName": "ColumnAmountO3",
        "dataFieldShortName": "Column Amount Ozone",
        "dataFieldLongName": "Ozone Total Column (TOMS-like)",
        "dataFieldLongNameText": [
          "Ozone Total Column (TOMS-like)",
          "Ozone"
        ],
        "dataFieldDescriptionUrl": "http://disc.gsfc.nasa.gov/techlab/giovanni/G3_manual_parameter_appendix.shtml#col_amt_ozone",
        "dataFieldMeasurement": [
          "Ozone"
        ],
        "dataFieldKeywordsString": [
          "Ozone",
          "Column",
          "Amount",
          "Ozone",
          "OMI",
          "TOMS-like",
          "Total",
          "ColumnAmountO3",
          "",
          "OMTO3e",
          "Aura",
          "Aura",
          "OMI",
          "Ozone Monitoring Instrument",
          "daily"
        ],
        "dataFieldKeywordsText": [
          "Ozone",
          "Column",
          "Amount",
          "Ozone",
          "OMI",
          "TOMS-like",
          "Total",
          "ColumnAmountO3",
          "",
          "OMTO3e",
          "Aura",
          "Aura",
          "OMI",
          "Ozone Monitoring Instrument",
          "OMI",
          "daily"
        ],
        "dataFieldDiscipline": [
          "Atmospheric Chemistry"
        ],
        "dataFieldKeywords": [
          "Column",
          "Amount",
          "Ozone",
          "OMI",
          "TOMS-like",
          "Total"
        ],
        "dataFieldTags": [
          "Atmospheric Composition Portal",
          "Basic",
          "Omnibus"
        ],
        "dataFieldAccessName": "ColumnAmountO3",
        "dataFieldAccessMethod": "OPeNDAP",
        "dataFieldAccessFormat": "netCDF",
        "dataFieldAccessFormatVersion": "",
        "dataFieldStandardName": "",
        "dataFieldFillValueFieldName": "_FillValue",
        "dataFieldUnits": "DU",
        "dataFieldLastModified": "2014-08-20T19:30:28.395Z",
        "dataFieldLastPublished": "2014-08-20T19:30:28.846Z",
        "dataFieldNominalMinValue": 100.0,
        "dataFieldNominalMaxValue": 500.0,
        "dataFieldAccumulatable": false,
        "dataFieldDeflationLevel": 1,
        "dataFieldSldUrl": "<slds><sld url=\"http://dev-ts2.gesdisc.eosdis.nasa.gov/giovanni/sld/divergent_rdbu_10_sld.xml\" label=\"Red-Blue (Div), 10\"/></slds>",
        "dataProductId": "OMTO3e.003",
        "dataProductDataSetId": "OMI/Aura TOMS-Like Ozone and Radiative Cloud Fraction Daily L3 Global 0.25x0.25 deg V003",
        "dataProductShortName": "OMTO3e",
        "dataProductVersion": "003",
        "dataProductLongName": "OMI/Aura TOMS-Like Ozone and Radiative Cloud Fraction Daily L3 Global 0.25x0.25 deg",
        "dataProductDescriptionUrl": "http://gcmd.gsfc.nasa.gov/getdif.htm?GES_DISC_OMTO3e_V003",
        "dataProductGcmdEntryId": "GES_DISC_OMTO3e_V003",
        "dataProductProcessingLevel": "3",
        "dataProductDataCenter": "NASA/GSFC/SED/ESD/GCDC/GESDISC",
        "dataProductPlatformShortName": "Aura",
        "dataProductPlatformLongName": "Aura",
        "dataProductInstrumentShortName": "OMI",
        "dataProductInstrumentLongName": "Ozone Monitoring Instrument",
        "dataProductPlatformInstrument": "OMI",
        "dataProductSpatialResolutionLatitude": 0.25,
        "dataProductSpatialResolutionLongitude": 0.25,
        "dataProductSpatialResolution": "0.25 deg.",
        "dataProductSpatialResolutionUnits": "deg.",
        "dataProductBeginDateTime": "2004-10-01T00:00:00Z",
        "dataProductWest": -180.0,
        "dataProductNorth": 90.0,
        "dataProductEast": 180.0,
        "dataProductSouth": -90.0,
        "dataProductTimeInterval": "daily",
        "dataProductTimeFrequency": 1,
        "dataProductStartTimeOffset": 1,
        "dataProductOpendapUrl": "http://acdisc.gsfc.nasa.gov/opendap/HDF-EOS5/Aura_OMI_Level3/OMTO3e.003//2004/OMI-Aura_L3-OMTO3e_2004m1001_v003-2012m0409t101417.he5.html",
        "dataProductResponseFormat": "netCDF",
        "sswBaseSubsetUrl": "http://dev-ts2.gesdisc.eosdis.nasa.gov/daac-bin/SSW/SSW?action=SUBSET;no_attr_prefix=1;content_key_is_value=1;force_array=1;pretty=0;format=netCDF;dataset_id=OMI%2FAura%20TOMS-Like%20Ozone%20and%20Radiative%20Cloud%20Fraction%20Daily%20L3%20Global%200.25x0.25%20deg%20V003;agent_id=OPeNDAP;variables=ColumnAmountO3",
        "_version_": 1508064019951386624,
        "dataFieldLastIndexed": "2015-07-29T20:32:03.259Z",
        "dataProductEndDateTime": "2010-12-31T23:59:59Z"
      }
    ]
  }
}
"""
        self.varSize[varId] = 1206587
        correctEstimate = self.varSize[varId] * 2283 / (1.0e6)
        self.runSingleTest(
            varId, correctEstimate, self.getCatalogInfo, self.getFileSize)

if __name__ == "__main__":
    unittest.main()
