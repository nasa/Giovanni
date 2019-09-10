"""
Tests for the agiovanni.celeryconfigBase module.
"""
import unittest
import mock
from mock import MagicMock, patch
import os
import shutil
import filecmp
import random
import tempfile

from agiovanni import celeryconfigBase

class celeryconfigBase_unitTest(unittest.TestCase):
    '''
    unit test for celeryconfigBase module
    '''

    def setUp(self):
        '''
        set up
        '''
        self.outputDir = tempfile.mkdtemp()
        celeryconfigFileContent = '\
        {\
            "BROKER_URL" : "redis://localhost:6379/",\
            "CELERY_IMPORTS" : ["agiovanni.visualizationManager"],\
        \
            "CELERY_RESULT_BACKEND" : "redis://localhost:6379/",\
            "CELERY_RESULT_PERSISTENT" : true,\
        \
            "CELERY_QUEUES" : {\
                "visualizationManager": {\
                    "binding_key": "visualizationManager.#"\
                }\
            },\
        \
            "CELERY_DEFAULT_EXCHANGE_TYPE" : "topic"\
        }'
        self.celeryconfigFile = os.path.join(self.outputDir, 'dummy_celeryconfig.json')
        with open(self.celeryconfigFile,'w') as fo:
            fo.write(celeryconfigFileContent)
        self.celeryconfigBase_object = celeryconfigBase.celeryconfigBase(self.celeryconfigFile)
        
    def test_parseJson(self):
        '''
        unit test for celeryconfigBase.parseJson method
        '''
        # call 
        result = celeryconfigBase.celeryconfigBase.parseJson(self.celeryconfigFile)
        
        # assert
        expected_result = {u'CELERY_QUEUES': {u'visualizationManager': {u'binding_key': u'visualizationManager.#'}}, u'CELERY_DEFAULT_EXCHANGE_TYPE': u'topic', u'CELERY_IMPORTS': [u'agiovanni.visualizationManager'], u'CELERY_RESULT_PERSISTENT': True, u'BROKER_URL': u'redis://localhost:6379/', u'CELERY_RESULT_BACKEND': u'redis://localhost:6379/'}
        self.assertEqual(result, expected_result)

    def test_merge(self):
        '''
        unit test for celeryconfigBase.merge method
        '''
        # preparation
        celeryconfigFileContent = '\
        {\
            "BROKER_URL" : "redis://localhost:6379/",\
            "CELERY_IMPORTS" : ["agiovanni.visualizationTask"],\
        \
            "CELERY_RESULT_BACKEND" : "redis://localhost:6379/",\
            "CELERY_RESULT_PERSISTENT" : true,\
        \
            "CELERY_QUEUES" : {\
                "visualizationTask": {\
                    "binding_key": "visualizationTask.#"\
                }\
            },\
        \
            "CELERY_DEFAULT_EXCHANGE_TYPE" : "topic",\
            "CELERY_ROUTES" : {\
                "agiovanni.visualizationTask.visualizationTask": {\
                    "queue": "visualizationTask",\
                    "routing_key": "visualizationTask.#"\
                }\
            }\
        }'
        another_celeryconfigFile = os.path.join(self.outputDir, 'dummy_another_celeryconfig.json')
        with open(another_celeryconfigFile,'w') as fo:
            fo.write(celeryconfigFileContent)

        # call
        self.celeryconfigBase_object.merge(another_celeryconfigFile)
        
        # assert
        result = self.celeryconfigBase_object.params
        expected_result = {u'CELERY_QUEUES': {u'visualizationTask': {u'binding_key': u'visualizationTask.#'}, u'visualizationManager': {u'binding_key': u'visualizationManager.#'}}, u'CELERY_DEFAULT_EXCHANGE_TYPE': u'topic', u'CELERY_IMPORTS': [u'agiovanni.visualizationManager', u'agiovanni.visualizationTask'], u'CELERY_ROUTES': {u'agiovanni.visualizationTask.visualizationTask': {u'queue': u'visualizationTask', u'routing_key': u'visualizationTask.#'}}, u'CELERY_RESULT_PERSISTENT': True, u'BROKER_URL': u'redis://localhost:6379/', u'CELERY_RESULT_BACKEND': u'redis://localhost:6379/'}
        self.assertEqual(result, expected_result)

    def tearDown(self):
        '''
        clean up
        '''
        shutil.rmtree(self.outputDir)

if __name__ == '__main__':
    unittest.main()
