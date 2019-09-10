""" 
NAME
NcFile.py - NetCDF file class

DESCRIPTION
This module provides methods for accessing information in a
NetCDF file.

SYNOPSIS
ncfile = NcFile.NcFile('in.nc')
ncfile.get_attribute(attrName, varName=None)
ncfile.get_all_dimensions()
ncfile.get_data1D(vname,type=None)
ncfile.get_fillvalue(v)
ncfile.get_latitude_dimension()
ncfile.get_longitude_dimension()
ncfile.get_z_dimension()
ncfile.get_time_dimension()
ncfile.get_max_value(vname)
ncfile.get_min_value(vname)
ncfile.get_region_label()
ncfile.get_resolution()
ncfile.gridinfo(dimName, dimType=None)
ncfile.subset_bbox_cmd_pyver()
ncfile.shape(vname)

OPTIONS

AUTHORS
Jianfu Pan, 04/23/2012, Initial version

VERSION
$Revision: 1.16 $
""" 

import sys, os, getopt
from netCDF4 import Dataset
import numpy


class NcFile:
    'NetCDF file object'

    def __init__(self, file):
        self.file = file
        self.fh = Dataset(file)

    def __del__(self):
        if self.fh:  self.fh.close()


    def get_all_dimensions(self):
        'Get list of all dimension names'
        dimnames = self.fh.dimensions.keys()
        return dimnames
    
    def get_data1D(self, vname, dtype=None):
        vars = self.fh.variables
        if vname not in vars.keys():
            sys.stderr.write("WARNING %s not found" % (vname))
            return None
        var_tmp = vars[vname]
        var = var_tmp[:]
        if len(numpy.shape(var)) != 1:
            sys.stderr.write("WARNING %s is not 1D" % (vname))
            return None
        # Apply data type if provided
        if dtype == "int":
            var = [int(v) for v in var]
        var_converted = [str(var[i]) for i in range(len(var))]
        varString = " ".join(var_converted)
        return varString

    def get_time_dimension(self):
        'Get time dimension name'
        dimnames = self.fh.dimensions.keys()
        vars = self.fh.variables
        timeName = None
        for vname in dimnames:
            if vname == "time":
                timeName = vname
                break
    
            var = vars[vname]
            try:
                units = var.getncattr("units")
            except:
                units = None
            if units is not None and units[:4] == "secs":
               timeName = vname
               break
        return timeName
    
    def get_latitude_dimension(self):
        'Get latitude dimension name'
        dimnames = self.fh.dimensions.keys()
        vars = self.fh.variables
        latName = None
        for vname in dimnames:
			if vname not in vars:
				continue
			var = vars[vname]
			try:
				units = var.getncattr("units")
			except:
				units = None
			if units == "degrees_north":
				latName = vname
				break
        return latName
    
    def get_longitude_dimension(self):
        'Get longitude dimension name'
        dimnames = self.fh.dimensions.keys()
        vars = self.fh.variables
        lonName = None
        for vname in dimnames:
			if vname not in vars:
				continue
			var = vars[vname]
			try:
				units = var.getncattr("units")
			except:
				units = None
			if units == "degrees_east":
				lonName = vname
				break
        return lonName

    def get_z_dimension(self):
        'Get vertical dimension name'
        dimnames = self.fh.dimensions.keys()
        vars = self.fh.variables
        zName = None
        for vname in dimnames:
            if vname in vars:
                var = vars[vname]
                try:
                    axis_type = var.getncattr("_CoordinateAxisType")
                except:
                    axis_type = None
                if axis_type == "GeoZ":
                   zName = vname
                   break
        return zName


    def get_attribute(self, attrName, varName=None):
        ' Get an attribute value '
        if varName is None:
            # We are getting a global attribute
            try:
                attrValue = self.fh.getncattr(attrName)
            except:
                attrValue = None
        else:
            # Getting variable's attribute
            try:
                attrValue = self.fh.variables[varName].getncattr(attrName)
            except:
                attrValue = None
        return attrValue


    def get_fillvalue(self, v=None):
        ' Get fillvalue of variable v'
        variables = self.fh.variables
        dimlist = self.fh.dimensions.keys()
        varlist = self.fh.variables.keys()
        sci_varlist = list(set(varlist) - set(dimlist))
    
        # Initialize fillvalue to None
        fillvalue = None

        # Select a variable to get its fillvalue
        if v is not None:  var = variables[v]
        else:
            for v in sci_varlist:
                if v not in ['dataday', 'datamonth', 'time_bnds','lat_bnds','lon_bnds']:
                    var = variables[v]
                    break

        # Find fillvalue by checking several fillvalue attributes
        for tag in ("_FillValue", "h5__FillValue", "missing_value"):
            try:
                fillvalue = var.getncattr(tag)
                break
            except:
                sys.stderr.write("WARN No " + tag + " found for " + v + "\n")
    
        return fillvalue

    def get_min_value(self, varname):
        'Get minimum data value of a variable'
        vars = self.fh.variables
        if varname not in vars.keys():
            return None
        minValue = numpy.min(vars[varname][:])

        # Apply scaling if needed
        # -- not needed as netCDF4 seems taking of this
        #-scale,offset = 1.0,0.0
        #-try:
        #-    scale = vars[varname].scale_factor
        #-    offset = vars[varname].add_offset
        #-    minValue = minValue * scale - offset
        #-except:
        #-    print "INFO No scaling info"
        return minValue

    def get_max_value(self, varname):
        'Get maximum data value of a variable'
        vars = self.fh.variables
        if varname not in vars.keys():
            return None
        maxValue = numpy.max(vars[varname][:])

        # Apply scaling if needed
        #-scale,offset = 1.0,0.0
        #-try:
        #-    scale = vars[varname].scale_factor
        #-    offset = vars[varname].add_offset
        #-    maxValue = maxValue * scale - offset
        #-except:
        #-    print "INFO No scaling info"
        return maxValue

    def get_region_label(self):
        'Get a region label'
        latName = self.get_latitude_dimension()
        lonName = self.get_longitude_dimension()
        variables = self.fh.variables
        lat = variables[latName]
        lon = variables[lonName]
        lat0, lat1 = lat[0], lat[-1]
        lon0, lon1 = lon[0], lon[-1]
        if lat0 < lat1:
            south, north = lat0, lat1
        else:
            south, north = lat1, lat0
        if lon0 < lon1:
            west, east = lon0, lon1
        else:
            west, east = lon1, lon0
        
        label = ""
        if west < 0:  label = label + str(-west) + "W-"
        else:         label = label + str(west) + "E-"
        if east < 0:  label = label + str(-east) + "W"
        else:         label = label + str(east) + "E, "
        if south < 0: label = label + str(-south) + "S-"
        else:         label = label + str(south) + "N-"
        if north < 0: label = label + str(-north) + "S"
        else:         label = label + str(north) + "N"

        return label

    def get_resolution(self):
        latName = self.get_latitude_dimension()
        lonName = self.get_longitude_dimension()
        variables = self.fh.variables
        lat = variables[latName]
        lon = variables[lonName]
        dlat = abs(lat[1]-lat[0])
        dlon = abs(lon[1]-lon[0])

        # Return highest resolution
        if dlat < dlon:  return dlat
        else:            return dlon

    def gridinfo(self, dimName, dimType=None):
        """ This method produces start value, resolution, and number of
            array elsements of a dimension variable, assuming the dimension
            is regularly gridded.
            Inputs:
              dimName : Name of dimension variable
              dimType : dimension type [lat, lon]
            Return:
              start,resolution,size  (when successful)
              None                   (when failed)
        """

        fail = None, None, None

        dimnames = self.fh.dimensions.keys()
        vars = self.fh.variables

        # Make sure dimension variable is in file
        if not vars.has_key(dimName):
            sys.stderr.write("ERROR dimension variable %s not found" % (dimName))
            return fail

        # Get dimension variable data
        dimData = vars[dimName]
        n = len(dimData)

        # Assuming regular grids and get resolution based on even step
        # division ;between 2nd and 2nd to last points to 
        # avoid abnormal boundary points, then derive the start value.
        # TBD: This is overly simplified algorithm and more strict implementation
        #      is needed in future.
        [_, delta] = numpy.linspace(dimData[1], dimData[-2], num = len(dimData)-2, retstep=True, endpoint = True)
        d0 = float(int((dimData[1] - delta) * 1000000)/1000000.)
        d_last = d0 + delta * (n-1)

        # Sanity check for giving dimension type
        if dimType == "lat":
            if d0 < -90:
                sys.stderr.write("ERROR Latitude out of south bound: %d" % (d0))
                return fail
            if d_last > 90:
                sys.stderr.write("ERROR Latitude out of north bound: %d" % (d_last))
                return fail
        elif dimType == "lon":
            if d0 < -180:
                sys.stderr.write("ERROR Longitude out of west bound: %d" % (d0))
                return fail
            if d_last > 360:
                sys.stderr.write("ERROR Longitude out of east bound: %d" % (d_last))
                return fail
        
        return d0, delta, n

    def shape(self,vname):
        vars = self.fh.variables
        if vname not in vars.keys():
            sys.stderr.write("WARN %s not found\n" % (vname))
            return None
        s = vars[vname].shape
        return '%d,%d,%d' % (s[0],s[1],s[2])

    # returns the bbox it was given if the box is not too small
    def subset_bbox_cmd_pyver(self,bbox):
        # copied from get_resolution which unfortunately
        # returns only the largest res
        latName = self.get_latitude_dimension()
        lonName = self.get_longitude_dimension()
        variables = self.fh.variables
        lat = variables[latName]
        lon = variables[lonName]
        dlat = abs(lat[1]-lat[0])
        dlon = abs(lon[1]-lon[0])

        bboxArray  = bbox.split(",")
        bboxArray  = map(float,bboxArray)
        if (abs(bboxArray[2]-bboxArray[0]) < dlon): 
               pointLon = (bboxArray[2]+bboxArray[0])/2.0
               bboxArray[2] = pointLon
               bboxArray[0] = pointLon
        if (abs(bboxArray[3]-bboxArray[1]) < dlat): 
               pointLat = (bboxArray[3]+bboxArray[1])/2.0
               bboxArray[3] = pointLat
               bboxArray[1] = pointLat
        bboxArray  = map(str,bboxArray)
        self.snapped_bbox = bboxArray; # note: not necessarily snapped
 
        return ','.join(bboxArray)

    # Since histogram subsets and averages in one step, we want to do a
    # subset and find out what nco did and then report that. So 
    # This is sort of a dry-run of ncea/ncks to determine what bbox was used
    # for the histogram (actual grid can very from user's bounding box)
    def determine_bbox_from_dry_run(self):
        cmd = 'ncks -d lon,' + float(self.snapped_bbox[0]) + ',' + float(self.snapped_bbox[2]) \
            + ' -d lat,'     + float(self.snapped_bbox[1]) + ',' + float(self.snapped_bbox[3])  
    

          
