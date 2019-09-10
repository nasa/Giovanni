"""
Shapefile Utility Class

Provides a library class useful shapefiles tasks. A frontend to the shapefile
preprocessing capabilities this library can be found in g4_shp_preprocess.py.
"""

__author__ = ('Aaron Plave (2014 Summer Intern)',
              'Daniel da Silva <daniel.dasilva@nasa.gov>')

import codecs
import os
import sys

import shapefile
import simplejson as json

from agiovanni.cfg import ConfigEnvironment


class ShapefileUtility:
	def __init__(self):
		self.Reader = None;
		self.Writer = None;
		self.Editor = None;
		self.uniqueIDField = "gShapeID"
		self.indexOfUniqueIDField = None;

        def findProvisionedShapefiles(self, config_env=None):
                """
                Returns a list of provision shapefile identifiers (shapefile prefixes)
                available in the current installation.
                """
                if config_env is None:
                        config_env = ConfigEnvironment()

                provisioned_dir = config_env.get("$GIOVANNI::SHAPEFILES{provisioned_dir}")
                
                # Select the prefixes based on the existance of %(prefix).json
                # files in the directory.
                prefixes = []
                
                for fname in os.listdir(provisioned_dir):
                        prefix, ext = os.path.splitext(fname)
                        if ext == '.json':
                                prefixes.append(prefix)

                return prefixes

        def readProvisionedInfo(self, prefix, config_env=None):
                """
                Returns the contents of the info file mapped from JSON to python
                objects.
                """
                if config_env is None:
                        config_env = ConfigEnvironment()

                provisioned_dir = config_env.get("$GIOVANNI::SHAPEFILES{provisioned_dir}")
                fname = prefix + '.json'
                info_path = os.path.join(provisioned_dir, fname)
                info = json.load(open(info_path))

                return info                
                                
	def determineBestAttribute(self):
		"""
		Determines best, if any, attribute(s) to use for labelling 
		the data. 
		Returns:
			False, if no fields
			?? None, if there are no unique fields
			<FieldX>, if FieldX is the only unique field
			<FieldX[NAME]>, where FieldX (is the first?) attr == 'NAME' or 'FULLNAME' 
			<FieldX[...NAME...]>, where FieldX (is the first?) attr CONTAINS 'NAME' or 'FULLNAME' 
			[<FieldX>,<FieldY>,<FieldZ>], if not previous condition, 
				return all unique fields with alphanumeric type
			[<FieldX>,<FieldY>,<FieldZ>], if not previous condition, 
				return all unique fields with other types

		"""
		# a = [('DeletionFlag', 'C', 1, 0),
		# 	 ['Permanent_', 'C', 40, 0],
		# 	 ['FDate', 'D', 8, 0],
		# 	 ['Resolution', 'C', 6, 0],
		# 	 ['GNIS_ID', 'C', 10, 0],
		# 	 ['GNIS_Name', 'C', 65, 0],
		# 	 ['AreaSqKm', 'F', 19, 11],
		# 	 ['Elevation', 'F', 19, 11],
		# 	 ['FTYPE', 'C', 24, 0],
		# 	 ['FCode', 'N', 9, 0]]

		fields = self.Reader.fields
		records = self.Reader.records()

		# Case of no fields (should never happen)
		if not fields:
			print "No fields found for:",self.Reader.shapeName
			return False

		# Get rid of deletion flag, if it's there (which I think it might always be)
		if fields[0][0].lower() == "deletionflag":
			print "Found 'deletionflag' in:",self.Reader.shapeName,"--removing"
			fields = fields[1:]

		# Determine which fields are unique: returns a list of indicies of unique fields
		uniqueFields = []
		for i in xrange(len(fields)):
			previousVal = None
			unique = True
			for j in xrange(len(records)):
				if records[j][i] == previousVal:
					unique = False
					break
				else:
					previousVal = records[j][i]
			if unique:
				uniqueFields.append(i)

		print "Unique field indicies:", uniqueFields

		# These next checks return tuples in the form [<fieldName>,index_in_fields]. If 
		# one of the elements found is a unique field, return this element 
		# (or the first unique one found in the set). Otherwise in the case of no unique elements
		# found in the search, store the results and move on. If by the end none of the results
		# belong to unique fields, just choose the first element in the results, since this will
		# follow the ranking hierarchy.

		results = []

		# Try to find fields == "name"
		fieldsEqualName = [(i[0],fields.index(i)) for i in fields if "name" == str(i[0]).lower()]
		# print fieldsEqualName,"Fields == name"
		if fieldsEqualName:
			unique = [i for i in fieldsEqualName if i[1] in uniqueFields]
			if unique:
				# which one...? Going to grab first one for now. 
				self.bestAttr = unique[0]
				return True
			else:
				results += fieldsEqualName

		# Try to find fields == "fullname"
		fieldsEqualFullname = [(i[0],fields.index(i)) for i in fields if "fullname" == str(i[0]).lower()]
		# print fieldsEqualFullname,"Fields == fullname"
		if fieldsEqualFullname:
			unique = [i for i in fieldsEqualFullname if i[1] in uniqueFields]
			if unique:
				# which one...? Going to grab first one for now. 
				self.bestAttr = unique[0]
				return True
			else:
				results += fieldsEqualFullname

		# Try to find fields containing "name"
		fieldsWithName = [(i[0],fields.index(i)) for i in fields if "name" in str(i[0]).lower()]
		# print fieldsWithName,"Fields with name"
		if fieldsWithName:
			unique = [i for i in fieldsWithName if i[1] in uniqueFields]
			if unique:
				# which one...? Going to grab first one for now. 
				self.bestAttr = unique[0]
				return True
			else:
				results += fieldsWithName

		# Try to find something with "id"
		fieldsWithID = [(i[0],fields.index(i)) for i in fields if "id" in str(i[0]).lower()]
		# print fieldsWithID,"Fields with id"
		if fieldsWithID:
			unique = [i for i in fieldsWithID if i[1] in uniqueFields]
			if unique:
				# which one...? Going to grab first one for now. 
				self.bestAttr = unique[0]
				return True
			else:
				results += fieldsWithID

		# if no unique results, grab first result, if exists
		if results:
			self.bestAttr = results[0]
			return True

		# If the above checks turn up nothing, grab the first "C" (i.e. character) field 
		# (aside from deletionFlag, which is assumed to be the first field)
		charFields = [(i[0],fields.index(i)) for i in fields if "c" in str(i[1]).lower()]
		# print charFields,"Char fields"
		if charFields:
			self.bestAttr = charFields[0]
			return True

		# If all else fails, grab the first thing.
		self.bestAttr = (fields[0][0],1)
		return True

	def addUniqueShapeIDs(self,filepath):
		"""
		Adds a field called gShapeID to the main 'fields' and unique shapeIDs to 
		"""
		# Remove this really, really annoying deletionFlag
		if self.Editor.fields[0][0].lower() == "deletionflag":
			print "Found 'deletionflag' in:",self.Reader.shapeName,"--removing"
			del self.Editor.fields[0]

		# Check to see if gShapeID is already in the fields
		# if so,  get all indicies where it exists, and remove each from the 
		# fields and from the records
		exists = []
		for i in xrange(len(self.Editor.fields)):
			# print self.Editor.fields[i][0]
			if self.Editor.fields[i][0] == self.uniqueIDField:
				exists.append(i)
		if exists:
			print "Found pre-existing uniqueID field(s), removing"
			for i in exists:
				# Remove field from fields
				del self.Editor.fields[i]

				# Remove field value from each shape
				for j in xrange(len(self.Editor.records)):
					del self.Editor.records[j][i]

		
		# Add gShapeID field
		print "Adding uniqueIDField to fields"
		self.Editor.field(self.uniqueIDField,"C",30)

		# Set the indexOfUniqueIDField class member. This is so the uniqueIDField can be
		# accessed later. Assumes that self.Editor.field will always append to the fields
		# list and not add it anywhere else in the list. Think this is a fair assumption.
		self.indexOfUniqueIDField = len(self.Editor.fields)

		print "Adding IDs to shapes..."
		# For each shape, add the field value of shp_ + some n
		for i in xrange(len(self.Editor.records)):
			self.Editor.records[i].append("shp_"+str(i))

		# Set shapeType. Important.
		self.Editor.shapeType = 5

		# Save
		print "Saving"
		# SHOULD we overwrite the original or make a new one, delete the old one
		# If no overwrite, change the foldername.. ick.. hm..
		# Overwriting for now.
		self.Editor.save(filepath)

		# Reset the Reader and the init the Writer
		print "DONE"
		self.Reader = shapefile.Reader(filepath)
		self.Writer = shapefile.Writer()
		self.Writer.fields = self.Reader.fields
		return True

	def loadShapefile(self,filepath):
		"""
		Attempts to load a shapefile from the filepath
		-Note: the shapefile lib is extension agnostic, so filepath
		       extension is irrelevant 
		"""
                # init reader from filepath, init writer
                self.Reader = shapefile.Reader(filepath)
                self.Editor = shapefile.Editor(filepath)
			
                # get parent directory
                self.parentDir = os.path.basename(filepath)
 
                # Determine best attribute
                if not self.determineBestAttribute():
                        raise RuntimeError("determine best attribute failed")

                print "best attr = ",self.bestAttr

                # Add unique IDs to shapes
                if not self.addUniqueShapeIDs(filepath):
                        raise RuntimeError("Unable to add unique shapeIDs")

	def extractShape(self, shape, record, filepath):
		"""
		Extracts the (shape, record) into a shapefile
		"""
                # Set shape type to Polygon!
                self.Writer.shapeType = 5

                # Add to writer
                self.Writer.records.append(record)
                self.Writer.shapes().append(shape)
                
                # Save
                self.Writer.save(filepath)

	def extractAllShapes(self, folderpath, basename):
		"""
		Filepath is something like 'extracted_shapes/'
		Extracts all shapes in the shapefile and saves each to a new
		shapefile (to filepath + something, just an iterator for now)
		"""
                # create shape and record generators
                # GENERATORS SEEM TO BE BUGGY? Something is definitely weird and 
                # I'm pretty sure I'm using them correctly.. switching to lists.
                records = self.Reader.records()
                shapes = self.Reader.shapes()

                for i in xrange(self.Reader.numRecords):	
                        # Get current shape and record
                        currentRecord = records[i]
                        currentShape = shapes[i]			

                        # Reset writer records and shapes  
                        self.Writer.records = []
                        del self.Writer.shapes()[:]			

                        # Decide on some filename..
                        commonName = basename + str(i+1)
                        folderName = folderpath + commonName			

                        # Create a new directory for this shapefile
                        if not os.path.exists(folderName):
                                os.mkdir(folderName)
                        else:
                                return folderName + " already exists as a directory, stopping"
                                # LATER refactor the error handling in this lib, make it part of the class

                        # Save with filepath + some identifier
                        shapefileName = folderName+"/"+ commonName
                        # print "Writing",shapefileName,"to",folderName
                        # print "Current Record:",currentRecord
                        # print "Current Shape:",currentShape
                        errors = self.extractShape(currentShape,currentRecord,shapefileName)
                        if errors:
                                raise RuntimeError("Unable to extract all shapes, error")


	def writeInfo(self,filepath, title=None, label_idx=None, source_name=None,
                      source_url=None):

                assert title, 'Title cannot be empty or None'
                
                """
		Writes in JSON format the attributes/values tables, and bounding boxes
		of each shape to a single file. 
		"""	
                records = self.Reader.records()
                shapes = self.Reader.shapes()
                fields = self.Reader.fields

                # Get rid of deletion flag, if it's there (which I think it might always be)
                if fields[0][0].lower() == "deletionflag":
                        print fields[0], "found 'deletionflag' in:",self.Reader.shapeName,"--removing"
                        fields = fields[1:]

                outData = {}
                strippedName = self.Reader.shapeName.split("/")[-1]
			
                outData["parentDir"] = self.parentDir 
                outData["shapefileID"] = strippedName
                outData["fields"] = fields
                
                outData["title"] = title
                outData['sourceName'] = source_name
                outData['sourceURL'] = source_url
                outData["uniqueShapeIDField"] = self.uniqueIDField
                outData["shapes"] = {}

                if label_idx is not None:
                        outData["bestAttr"] = ['', label_idx]
                else:
                        outData["bestAttr"] = self.bestAttr

                for i in xrange(self.Reader.numRecords):	
                        # Get current shape and record
                        currentRecord = records[i]
                        currentShape = shapes[i]
                        boundingBox = list(currentShape.bbox)
                        shapeID = records[i][self.indexOfUniqueIDField-1]

                        outData["shapes"]["shp_"+str(i)] = {
                                "values":currentRecord,
                                "bbox":boundingBox,
                        }
                        
                # Replace bad UTF-8 characters before writing
                for shape in outData['shapes'].values():
                        values = shape['values']
                        for i in range(len(values)):
                                if not isinstance(values[i], basestring):
                                        continue
                                values[i] = codecs.decode(values[i], 'utf-8', 'ignore')                          
                # Now write to file
                outfile = open(filepath, "w")
                json.dump(outData,outfile,encoding='utf-8')
                outfile.close()


