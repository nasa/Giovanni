"""
Celery config module
This module creates a celery instance to be used by "/etc/default/celeryd" in the following line:
    CELERY_APP = "agiovanni.celeryGiovanni"

@author: Hailiang Zhang <hailiang.zhang@nasa.gov>
"""

import os
from celery import Celery
from agiovanni import celeryconfigBase

currentDir = os.path.dirname(os.path.realpath(__file__))
cfgDir = os.path.normpath(os.path.join(currentDir,'..','..','..','..','cfg'))  ## NOTE assume relative path of the cfg folder

celeryconfigFileName = 'celeryconfigVisManager.json'
celeryconfigFile = os.path.join(cfgDir,celeryconfigFileName)
o = celeryconfigBase.celeryconfigBase(celeryconfigFile)

celeryconfigFileName = 'celeryconfigVisTask.json'
celeryconfigFile = os.path.join(cfgDir,celeryconfigFileName)
o.merge(celeryconfigFile)

celeryconfigFileName = 'celeryconfigWorkflow.json'
celeryconfigFile = os.path.join(cfgDir,celeryconfigFileName)
o.merge(celeryconfigFile)

app = Celery('giovanni')

app.conf.update(o.params)
