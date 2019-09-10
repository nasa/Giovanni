#!/bin/env python
# -*- coding:  UTF-8 -*-
'''
Author:  Richard Strub
         2017-07-07

Purpose: FEDGIANNI-2473
         To clarify that these regions are not countries or states but watersheds

Synopsis: addWatershedToLabel.py watersheds.json [verbose=anything]

          copies the original watersheds.json to watersheds.json.org 
          updates watersheds.json
          You can then commit the watersheds.json if it checks out
'''
         

import simplejson as json
import sys
import shutil
import re

verbose = False

def printValues(values,names):

    for index in range(len(names)):
       sys.stdout.write(names[index] + ": ")
       if (type(items) == 'str'):
           sys.stdout.write(values[index])
       else:
           sys.stdout.write(str(values[index]) + ", ") 
    print "" 

def printShape(shape, names):
    printValues(shape['values'],names)

def dotheUpdate(shape,names,best, maxlen):
    for index in range(len(names)):
       if (names[index] == best):
            if (not re.search('watershed', shape['values'][index], flags=re.IGNORECASE)):
                shape['values'][index] += ' watershed'
                if (len(shape['values'][index]) >  maxlen):
                   print shape['values'][index] + " is too long " + str(len(shape['values'][index]))
                   sys.exit(1)
                if verbose:
                   print shape


if len(sys.argv) > 1:
   watershed_file = sys.argv[1] 
else:
   print 'USAGE:g4_shp_add_watershed.py watersheds.json [verbose]'
   sys.exit(0)
if len(sys.argv) > 2:
   verbose = True


# copy the original aside
try:
   keep_original = watershed_file + ".org"
   shutil.copyfile(watershed_file, keep_original)
except IOError:
   print keep_original + " already exists with preventative permissions\n"
   sys.exit()

# operate on the original:
try:
   f = open(watershed_file, "r")
   watershed_data = f.read()
   watersheds = json.loads(watershed_data)
except IOError:
   print '不能打开：that is, could not open ' + watershed_file
finally:
   f.close()
   
ValueNames = []
DictValues = [] # shapes
FieldNames = [] # names of the parts of each of the shapes
Best       = '' # the identifier
maxlen     = 0

# We need to do this because fields may be before bestAttr：
for key in watersheds.keys():
    if (key == 'bestAttr'):
       Best = watersheds[key][0]
       
for key in watersheds.keys():
    ValueNames.append(key)
    if type(watersheds[key]) is str:
       print 'String:' + key + ':' + watersheds[key]
    elif type(watersheds[key]) is list:
        print 'List:' + key + " has " + str(len(watersheds[key])) + " items"
    
        if (key == 'fields'): 
           for items in watersheds[key]:
               FieldNames.append(items[0])
               if (items[0] == Best):
                   maxlen =  items[2]
                   print "maxlen apparently is: " + str(maxlen)
    
    elif type(watersheds[key]) is dict: 
        print 'Hash:' + key + " has " + str(len(watersheds[key])) + " items"
        DictValues.append(key)

# Generally shapes are the only hash(dicts):
for dicts in DictValues:
    thisdict = watersheds[dicts];
    for shapes in thisdict.keys():
           thisShape = thisdict[shapes]
           if verbose:
              printShape(thisShape,FieldNames)
           dotheUpdate(thisShape,FieldNames,Best,maxlen)
          


# write to the original file
# the original has already been copied to watersheds.json.org
try:
   f = open(watershed_file, "w")
   f.write(json.dumps(watersheds))
except IOError:
   print '不能打开：Unable to open ' + watershed_file
finally:
   f.close()
