"""
Celery config module
Used by celery worker as "celery worker --config=agiovanni.celeryconfigVisTask"

@author: Hailiang Zhang <hailiang.zhang@nasa.gov>
"""

import os
from celery import Celery

from agiovanni import celeryconfigBase

currentDir = os.path.dirname(os.path.realpath(__file__))
cfgDir = os.path.normpath(os.path.join(currentDir,'..','..','..','..','cfg')) ## NOTE assume relative path of the cfg folder

celeryconfigWorkerFileName = 'celeryconfigVisTask.json'
celeryconfigFile = os.path.join(cfgDir,celeryconfigWorkerFileName)

o = celeryconfigBase.celeryconfigBase(celeryconfigFile)
o.startCelery()

