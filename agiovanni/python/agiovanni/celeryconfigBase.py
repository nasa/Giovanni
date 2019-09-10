"""
Base class of celeryconfig module

@author: Hailiang Zhang <hailiang.zhang@nasa.gov>
"""

import os
import json 
from celery import Celery

class celeryconfigBase(object):
    '''
    Base class of celeryconfig module
    '''
    def __init__(self, celeryconfigFile):
        '''
        constructor
        '''
        self.params = self.parseJson(celeryconfigFile)

    @staticmethod
    def parseJson(celeryconfigFile):
        '''
        Parse the celeryconfig file in json format so that it can be passed to celery command API
        e.g. celery worker --config='agiovanni.celeryconfigWorker' -l info
        '''
        with open(celeryconfigFile) as fin:
            params = json.load(fin)
        return params

    def merge(self, otherCeleryconfigFile):
        '''
        Merge the other the celeryconfig file in json format
        Note: this is a customized version
        '''
        with open(otherCeleryconfigFile) as fin:
            other_params = json.load(fin)
        for k,v_other in other_params.items():
            if k not in self.params:
                self.params[k] = v_other
            elif type(self.params[k])==list:
                v = self.params[k]
                self.params[k] = v+list(set(v_other)-set(v))
            elif type(self.params[k])==dict:
                self.params[k].update(v_other)

    def startCelery(self):
        '''
        start celery worker
        '''
        app = Celery()
        app.conf.update(**self.params)
        app.start()
