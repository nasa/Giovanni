#! /usr/bin/python
"""
NetCDF as shapefile Utility Class

Provides a library class for creating a 'shapefile' with a NetCDF file. A frontend to the 
preprocessing capabilities this library can be found in g4_shp_preprocess.py.
"""

__author__ = 'Richard Strub'


import codecs
import sys
import os
import getopt
import re
from subprocess import call
import numpy as np
from netCDF4 import Dataset
from collections import defaultdict
import simplejson as json

class NetCDFMaskFileUtility:

	def __init__(self,file1):
		self.uniqueIDField = "gShapeID"
		self.indexOfUniqueIDField = None
		self.inputfile = file1 + ".nc"
		self.varlist = []
		self.fields = defaultdict(list)
		self.values = defaultdict(list)
		self.parentDir = os.path.basename(file1)
		self.fieldnames = {}
      

	# Not Using: Decided we want to keep the name of the file .nc
	def rename_inputfile(self, titlename):
		 shapename = titlename + '.shp'
                 ncname    = titlename + '.nc'
                  
                 if (os.path.isfile(shapename)):
			return shapename 
		 elif (os.path.isfile(ncname)):
			os.rename(ncname,shapename)
			return shapename 
		 else:
			raise RuntimeError("Cannot find input file <" + titlename + "> with suffix .shp or .nc")	
 
	def buildFieldItemArray(self,name,value):
		 dtype =  self.TypeInString(value)
		 length = 0
		 if (dtype == 'C'):
			length = len(value)
		 thisfield = [name,dtype,length]
		 return thisfield

	def loadNetCDFFile(self):
		try:
			nc = Dataset(self.inputfile, 'a')
		except:
			raise RuntimeError("input file <" + self.inputfile + "> is not a valid netcdf file")	
			
		self.nc = nc

		for key in nc.variables:
			if (len(nc.variables[key].dimensions) >= 2):
				self.mainvar = key
				for dim in  nc.variables[key].dimensions:
					if re.match('^lat', dim,re.IGNORECASE):
						self.lat_name =  dim 
					elif re.match('^lon', dim,re.IGNORECASE):
						self.lon_name = dim
				self.varlist.append(nc.variables[key])
				self.long_name = nc.variables[key].long_name
		if (len(self.long_name) == 0):
			raise RuntimeError("The main variable " + key + " needs to have a long_name attribute")	

		self.addShapeID()
		self.createbbox()
		self.buildfields()
		
	def createbbox(self):
 		try:
			lat  = self.nc.variables[self.lat_name]
			lon  = self.nc.variables[self.lon_name]
			self.lat = lat
			self.lon = lon
		except:
			sys.stderr.write("ERROR lat,lon variables not found in %s\n" % (self.inputfile))
			exit(-1)

                self.boundingBox = [-180,-90,180,90]
		self.boundingBox[0] = float("%8.5f" % float(lon[0]))
		self.boundingBox[1] = float("%8.5f" % float(lat[0]))
		self.boundingBox[2] = float("%8.5f" % float(lon[-1]))
		self.boundingBox[3] = float("%8.5f" % float(lat[-1]))

	def addShapeID(self):
		nc = self.nc
		# non lat lon vars:
		i = 0
		for var in self.varlist:
			if var.name != self.lat_name and var.name != self.lon_name:
 				try:
					current_id =  self.getAttribute(var,self.uniqueIDField)
					self.fields[var._getname()].append(self.buildFieldItemArray(self.uniqueIDField,current_id))
				except:
					self.setAttribute(var,self.uniqueIDField,"shp_" + str(i))
				        self.fields[var._getname()].append(self.buildFieldItemArray(self.uniqueIDField,"shp_"+str(i)))
				++i
	

	def setAttribute(self,variable,attrname,attrvalue):
                print "Adding uniqueID attribute to file"
		variable.__setattr__(attrname,attrvalue)

	def getAttribute(self,variable,attrname):
		return variable.__getattr__(attrname)

	def buildfields(self):
		nc = self.nc
		# non lat lon vars:
		for var in self.varlist: # 2 di vars
                        vararray = []
                        # We are assinging bestattr to be the first field of our fields

			# The value of this is what appears in the GUI
			vararray.append(self.buildFieldItemArray("NAME",self.long_name))  
                        # We want the long_name of the variable to be the shape  name of the mask 
			self.values[var._getname()].append(self.SimpleTypes(var.long_name))

			for name in var.ncattrs():
				value  =  getattr(var,name)
				vararray.append(self.buildFieldItemArray(name,value))
				self.values[var._getname()].append(self.SimpleTypes(value))
			self.fields[var._getname()] =  vararray
		# global
                vararray = []
		for name in nc.ncattrs():
			value  =  getattr(nc,name)
			vararray.append(self.buildFieldItemArray(name,value))
			self.fieldnames[name] = 1
			self.values
                self.fields['global'] = vararray
                vararray = []
		for name in self.lat.ncattrs():
			value  =  getattr(self.lat,name)
			vararray.append(self.buildFieldItemArray(name,value))
			self.fieldnames[name] = 1
                self.fields['lat'] = vararray
                vararray = []
		for name in self.lon.ncattrs():
			value  =  getattr(self.lon,name)
			vararray.append(self.buildFieldItemArray(name,value))
			self.fieldnames[name] = 1
                self.fields['lon'] = vararray

	def SimpleTypes(self,obj):
			if type(obj) is str:
				return obj	
			if type(obj) is unicode:
			       return str(obj)	
			if type(obj) is float:
				return obj	
			if type(obj) is int:
				return obj	
			if type(obj) is long:
				return obj	
			if type(obj) is np.int16:
				return int(obj)
			if type(obj) is np.int32:
				return long(obj)
			if type(obj) is np.float32:
				return float(obj)
			if type(obj) is np.float64:
				return float(obj)

	def TypeInString(self,obj):
			if type(obj) is str:
				return 'C'
			if type(obj) is unicode:
				return 'C'
			if type(obj) is float:
				return 'N'
			if type(obj) is int:
				return 'N'
			if type(obj) is long:
				return 'N'
			if type(obj) is np.int16:
				return 'N'
			if type(obj) is np.int32:
				return 'N'
			if type(obj) is np.float32:
				return 'N'
			if type(obj) is np.float64:
				return 'N'
			else:
				message = 'Could not determine type of: <'+ str(type(obj)) + '>'
				sys.stderr.write(message)
				sys.exit(2)	

        # This is very similar to the ESRI version in shapefileUtilities.py:
	def writeInfo(self,filepath, title=None, label_idx=None, source_name=None,
                      source_url=None):

		# For .nc files, the title is the 'class' of files it belongs to, the .json file it is in.
       		# All of the land masks, say will be in Land_Mask.json. the title then should be Land_Mask.
		# title is a file level variable 
                assert title, 'Title cannot be empty or None'

                """
                Writes in JSON format the attributes/values tables, and bounding boxes
                of each shape to a single file. 
                """

                outData = {}

                outData["parentDir"] = self.parentDir
                outData["shapefileID"] = self.parentDir# basename
		outData["fields"] = []
		for var in  self.varlist:
                	outData["fields"] += self.fields[var._getname()] 

                # We want the title of the file to be what the user input as --title
                outData["title"] = title # defined on input
                outData['sourceName'] = source_name # defined on input
                outData['sourceURL'] = source_url # defined on input
                print "Adding uniqueIDField to fields"
                outData["uniqueShapeIDField"] = self.uniqueIDField # pretty mucha always 'gShapeID'
                outData["shapes"] = {}

                if label_idx is not None:
                        outData["bestAttr"] = ['NAME', 0] # The value of this is what appears in the GUI
                else:
                        outData["bestAttr"] = self.bestAttr

		for var in  self.varlist:
                        outData["shapes"][self.values[var._getname()][-1]] = {
                                "values":self.values[var._getname()],
                                "bbox":self.boundingBox,
                        }

                # Replace bad UTF-8 characters before writing
                for shape in outData['shapes'].values():
                        values = shape['values']
                        for i in range(len(values)):
                                if not isinstance(values[i], basestring):
                                        continue
                                values[i] = codecs.decode(values[i], 'utf-8', 'ignore')

                # Now write to file
		print "Saving"
                outfile = open(filepath, "w")
                json.dump(outData,outfile,encoding='utf-8')
                outfile.close()

				




