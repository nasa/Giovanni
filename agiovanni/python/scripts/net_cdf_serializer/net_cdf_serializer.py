#!/bin/env python
from scipy.constants.constants import year
__author__ = "Christine Smit <christine.e.smit@nasa.gov>"

import netCDF4 as nc
import numpy as np
import os
import argparse
import StringIO
from datetime import datetime,timedelta
import pytz
import sys

class NetCdfSerializer(object):
    """This class serializes a netcdf file to JSON. The netcdf file needs to have
    the following dimensions:
    <ol>
    <li>time</li>
    <li>lat - latitude</li>
    <li>lon - longitude</li>
    </ol>
    and one more more 3 dimensional variables with the time, lat, and lon
    dimensions in that order.
    """
    # The first time variable in the netcdf file.
    timeVariable = None

    # The time range from the
    timeRangeString = None

    # The latitude variable in the netcdf file.
    latitudeVariable = None

    # The longitude variable in the netcdf file.
    longitudeVariable = None

    # The data variables in the netcdf file.
    dataVariables = None # LinkedList

    # Data day variable, if it exists.
    dataDayVariable = None

    # Data month variable, if it exists.
    dataMonthVariable = None

    # The number of spaces for each indent level.
    NUM_SPACES = 2

    # Default number of significant digits
    SIGNIFICANT_DIGITS = 2
    # The netcdf file we are converting.
    file_ = None

    # The temporal resolution of the paired data.
    temporalResolution = None
  
    def __init__(self, netCdfFile):
        """Constructs a converter from a netcdf file.
         
        param netCdfFile
                the file we are going to convert.
        throws Exception
        """
        # initialize variables list
        self.dataVariables = []
        # open the netcdf file
        self.file_ = nc.Dataset(netCdfFile)
        # and the variables
        variables = self.file_.variables
        # go through the variables and find the latitude variable, longitude
        # variable, and data variables.
        for name in variables:
            if name == "lat":
                self.latitudeVariable = variables[name]
            elif name == "lon":
                self.longitudeVariable = variables[name]
            elif name == "dataday":
                self.dataDayVariable = variables[name]
            elif name == "datamonth":
                self.dataMonthVariable = variables[name]
            else:
                # see if this is a serializable data variable
                for att in variables[name].ncattrs():
                    if att == "plot_hint_axis_title":
                        self.dataVariables.append(variables[name])
                        
        # now figure out the time dimension variable of the first data
        # variable, if it exists
        if len(self.dataVariables) != 2:
            raise Exception("Expected to find 2 plot hint variables, actually found %d" % len(self.dataVariables))
        self.timeVariable = self.getTimeDimensionVariable(self.dataVariables[0], variables)
        # get the time resolution from global attributes
        globalAttributes = self.file_.ncattrs()
        for attribute in globalAttributes:
            if attribute == "temporal_resolution" or attribute == "input_temporal_resolution":
                self.temporalResolution = str(self.file_.getncattr(attribute))
        if self.temporalResolution == None:
            # default to hourly
            self.temporalResolution = "hourly"
        #  set the time range string
        self.setTimeRangeString()

    def getTimeDimensionVariable(self, dataVariable, variables):
        """Get the time dimension variable associated with a data variable
        param dataVariable
                    the data variable
        param variables
                    the variables in the file
        return the time dimension variable or None if it can't be found
        """
        dimensions = dataVariable.dimensions
        for dimension in dimensions:
            # find the variable with the same name
            for variable in variables:
                if variable == dimension:
                    # now see if this variable is a time dimension
                    standardName = self.getStandardName(variables[variable])
                    if standardName != None and standardName == "time":
                        return variables[variable]
        return None

    def getStandardName(self, variable):
        """Get the value of the standard_name attribute for a variable
         
        param variable
                    the variable
        return the standard_name or None if there is no standard_name
        """
        attributes = variable.__dict__
        for attribute in attributes:
            if attribute == "standard_name":
                return variable.getncattr(attribute)
        return None

    def convertNotStatic(self, significantDigits):
        """The object's conversion function to convert the file we've opened into
        JSON
        
        param significantDigits
                 the number of significant digits to write in the JSON.
        return the JSON string
        throws Exception
        """
        if significantDigits == None: significantDigits = self.SIGNIFICANT_DIGITS
        buf = StringIO.StringIO() # new StringBuffer(String.format("{\n"))
        buf.write("{\n")
        self.addTime(buf, significantDigits)
        buf.write(",\n")
        if self.latitudeVariable != None:
            self.addGeoDimension(buf, significantDigits, self.latitudeVariable)
            buf.write(",\n")
        if self.longitudeVariable != None:
            self.addGeoDimension(buf, significantDigits, self.longitudeVariable)
            buf.write(",\n")
        self.addDataVariables(buf, significantDigits, self.dataVariables)
        buf.write("\n}\n")
        return buf.getvalue()

    def addTime(self, buf, significantDigits):
        """Add the time variable
        
        param buf
        throws Exception
        """
        buf.write(self.getIndentStr(self.NUM_SPACES) + "\"time\": {\n")
        buf.write(self.getIndentStr(2 * self.NUM_SPACES) + "\"data\": \n")
        timeStrings = None
        if self.timeVariable == None:
            # we don't have a time variables, so use the the time range string
            timeStrings = [None]*1
            timeStrings[0] = self.timeRangeString
        else:
            # we have a time variable, so format it into strings
            if self.dataDayVariable != None:
                timeStrings = self.getFormattedDataDay()
            elif self.dataMonthVariable != None:
                timeStrings = self.getFormattedDataMonth()
            else:
                timeStrings = self.getFormattedTime()
        buf.write(self.getIndentStr(3 * self.NUM_SPACES) + "[")
        for i in range(len(timeStrings)):
            buf.write(" \"%s\"" % timeStrings[i])
            if i != (len(timeStrings) - 1):
                buf.write(",")
        buf.write("]\n" + self.getIndentStr(self.NUM_SPACES) + "}")

    def getFormattedDataDay(self):
        """Format date strings from the data day
        
        return
        throws IOException
        """
        timeArray = self.dataDayVariable[:]
        # Get the number of index positions. shape[] will be a one element
        # array.
        shape = timeArray.shape
        timeStrings = [None]*shape[0]
        for i in range(shape[0]):
            timeInt = timeArray[i]
            # The format of the time is YYYYDDD.
            year = timeInt / 1000
            day = timeInt - year * 1000
            time = datetime(year, 1, 1, 0, 0) #DateTime
            time = time + timedelta(day - 1) # TODO
            timeStrings[i] = self.convertTime(time, "daily")
        return timeStrings

    def getFormattedDataMonth(self):
        timeArray = self.dataMonthVariable[:]
        # Get the number of index positions. shape[] will be a one element
        # array.
        shape = timeArray.shape
        timeStrings = [None]*shape[0]
        for i in range(shape[0]):
            timeInt = timeArray[i]
            # The format of the time is YYYYMM.
            year = timeInt / 100
            month = timeInt - year * 100
            time = datetime(year, month, 1, 0, 0) #DateTime TODO
            timeStrings[i] = self.convertTime(time, "monthly")
        return timeStrings

    def getFormattedTime(self):
        """Format date strings from the time dimension.
        
        return string representations of the times in the time dimension
        throws Exception
        """
        timeArray = self.timeVariable[:]
        units = str(self.timeVariable.getncattr("units"))
        # Get the number of index positions. Time is a dimension, so shape[]
        # will be a one element array
        shape = timeArray.shape
        # get the date out of the units. This is the number after
        # "seconds since", "days since", etc.
        baseDate = self.getBaseDateTime(units)
        timeStrings = [None]*shape[0]
        for i in range(shape[0]):
            if units.startswith("seconds since"):
                value = round(timeArray[i])
                time = baseDate + timedelta(0,value)
            else:
                raise Exception("Unable to understand time units '%s'" % units)
            timeStrings[i] = self.convertTime(time, self.temporalResolution)
        return timeStrings

    def getBaseDateTime(self, units):
        """ Create a DateTime from the stuff after '... since' in the units string. I
        assume this string looks like 'YYYY-MM-DD HH:MM:SS'
        
        param units
        return the date
        TODO: find out about the date format for CF-1 compliance!
        """
        beginIndex = units.index('since ') + len('since ')
        dateString = units[beginIndex:]
        # first four numbers are the year
        return self.getDateTime(dateString)

    def getDateTime(self, dateString):
        """Creates a DateTime from strings that look like 'YYYY-MM-DD hh:mm:ss' or
        'YYYY-MM-DDThh:mm:ssZ'
        
        param dateString
        return the date
        """
        year = int(dateString[0:4])
        month = int(dateString[5:7])
        day = int(dateString[8:10])
        hour = int(dateString[11:13])
        minute = int(dateString[14:16])
        second = int(dateString[17:19])
        return datetime(year, month, day, hour, minute, second, tzinfo=pytz.utc)

    def setTimeRangeString(self):
        """Figures out the time string based on the matched start and end time
        global attributes.
         
        throws Exception
        """
        attributes = self.file_.ncattrs()
        startTimeString = None
        endTimeString = None
        for att in attributes:
            if att=="matched_start_time":
                startTimeString = self.file_.getncattr(att)
            elif att=="matched_end_time":
                endTimeString = self.file_.getncattr(att)
        if startTimeString == None:
            raise Exception("Unable to find matched_start_time")
        elif endTimeString == None:
            raise Exception("Unable to find matched_end_time")
        formattedStartTime = self.convertTime(self.getDateTime(startTimeString), self.temporalResolution)
        formattedEndTime = self.convertTime(self.getDateTime(endTimeString), self.temporalResolution)
        if formattedStartTime == formattedEndTime:
            self.timeRangeString = formattedStartTime
        else:
            self.timeRangeString = formattedStartTime + " - " + formattedEndTime

    def convertTime(self, time, temporalResolution):
        """Convert the time into a string.
        
        param time
                   the time to convert
        param temporalResolution
                   the temporal resolution of the data
        return the date in YYYY-MM-DDTHH:MM:SSZ
        throws Exception
        """
        # make sure inputTime is UTC
        if time.tzinfo == None or time.tzinfo.utcoffset(time) == None:
            time = pytz.utc.localize(time)
        # create a formatter in the specific format we want
        date_format=''
        if temporalResolution==("monthly"):
            date_format += '%Y'
            date_format += '-'
            date_format += '%m'
        elif temporalResolution==("daily"):
            date_format += '%Y'
            date_format += '-'
            date_format += '%m'
            date_format += '-'
            date_format += '%d'
        # elif temporalResolution==("hourly"):
        #    pass  # fall through
        elif temporalResolution==("3-hourly") or temporalResolution==("hourly"):
            date_format += '%Y'
            date_format += '-'
            date_format += '%m'
            date_format += '-'
            date_format += '%d'
            date_format += ' '
            date_format += '%H'
            date_format += 'Z'
        elif temporalResolution==("half-hourly"):
            date_format += '%Y'
            date_format += '-'
            date_format += '%m'
            date_format += '-'
            date_format += '%d'
            date_format += ' '
            date_format += '%H'
            date_format += ':'
            date_format += '%M'
            date_format += 'Z'
        else:
            raise Exception("Unrecognized temporal resolution '" + temporalResolution + "'")
        return time.strftime(date_format)

    def addDataVariables(self, buf, significantDigits, dataVariables):
        """Add the data variables to the JSON string
        
        param buf
                  buffer holding the JSON string
        param significantDigits
                  number of significant digits for doubles/floats
        param dataVariables
                   list of the data variables
        throws Exception
        """
        for i in range(len(dataVariables)):
            var = dataVariables[i]
            attrs = var.__dict__
            # get the offset and scale factor, if they exist
            addOffset = 0
            if "add_offset" in attrs:
                addOffset = float(var.getncattr("add_offset"))
     
            scaleFactor = 1.
            if "scale_factor" in attrs:
                scaleFactor = float(var.getncattr("scale_factor"))
                
            # element name
            name = var.name
            buf.write(self.getIndentStr(self.NUM_SPACES) + "\"" + name + "\": {\n")

            # units (TT 26193)
            unitsStr = "1"
            if "units" in attrs:
                unitsStr = var.getncattr("units")
            buf.write(self.getIndentStr(2 * self.NUM_SPACES) + "\"units\": \"%s\",\n" % unitsStr)
            
            # quantity type
            quantity_type = var.getncattr("quantity_type")
            buf.write(self.getIndentStr(2 * self.NUM_SPACES) + "\"quantity_type\": \"%s\",\n" % str(quantity_type))
            
            # long name
            long_name = var.getncattr("long_name")
            buf.write(self.getIndentStr(2 * self.NUM_SPACES) + "\"long_name\": \"%s\",\n" % str(long_name))
            
            # product
            product_short_name = var.getncattr("product_short_name")
            buf.write(self.getIndentStr(2 * self.NUM_SPACES) + "\"product_short_name\": \"%s\",\n" % str(product_short_name))
            
            # version
            product_version = var.getncattr("product_version")
            buf.write(self.getIndentStr(2 * self.NUM_SPACES) + "\"product_version\": \"%s\",\n" % str(product_version))
            
            # fill value
            if "_FillValue" in attrs:
                fill = float(var.getncattr("_FillValue"))
                # correct with bias and offset
                fill = fill * scaleFactor + addOffset
                buf.write(self.getIndentStr(2 * self.NUM_SPACES) + "\"_FillValue\": [%s],\n" % self.printValue(fill, significantDigits))
            
            # plot hint axis title
            plot_hint_axis_title = var.getncattr("plot_hint_axis_title")
            buf.write(self.getIndentStr(2 * self.NUM_SPACES) + "\"plot_hint_axis_title\": \"%s\",\n" % str(plot_hint_axis_title))
            
            # put in the data
            buf.write(self.getIndentStr(2 * self.NUM_SPACES) + "\"data\": \n")
            
            array = var[:]
            # No need to scale data NetCDF4 lib does it for us, apparently
            # array = array * scaleFactor + addOffset
            # Unmask masked values, if any
            if isinstance(array, np.ma.core.MaskedArray):
                mask = np.ma.getmaskarray(array)
                array[mask] = fill

            # see if this is a 2D array or 3D array
            shape = array.shape
            if len(shape) == 3:
                self.writeArray(buf, array, significantDigits, 3 * self.NUM_SPACES, var.dtype)
            elif len(shape) == 2:
                # add a fake dimension layer first before calling write array
                buf.write(self.getIndentStr(3 * self.NUM_SPACES) + "[ " + "\n")
                self.writeArray(buf, array, significantDigits, 4 * self.NUM_SPACES, var.dtype)
                buf.write("\n" + self.getIndentStr(3 * self.NUM_SPACES) + "]")
            else:
                raise Exception("Expected data fields to be two or three dimensional variables")
            buf.write("\n" + self.getIndentStr(self.NUM_SPACES) + "}")
            if i != len(dataVariables) - 1:
                buf.write(",\n")

    def addGeoDimension(self, buf, significantDigits, var):
        """Add a latitude or longitude dimension
         
        param buf
                   buffer for JSON
        param significantDigits
                  significant digits for the lat & lon
        param var
                  the latitude or longitude variable
        throws Exception
        """
        name = var.name
        # element name
        buf.write(self.getIndentStr(self.NUM_SPACES) + "\"" + name + "\": {\n")
        # units
        units = str(var.getncattr("units"))
        buf.write(self.getIndentStr(2 * self.NUM_SPACES) + "\"units\": \"%s\",\n" % units)
        buf.write(self.getIndentStr(2 * self.NUM_SPACES) + "\"data\": \n")
        array = var[:]
        self.writeArray(buf, array, significantDigits, 3 * self.NUM_SPACES, var.dtype)
        buf.write("\n" + self.getIndentStr(self.NUM_SPACES) + "}")

    def getIndentStr(self, length):
        """Create an an array of spaces of length 'length'
        
        param length
                  the length of the array
        return a 'length' length space array
        """
        buf = StringIO.StringIO()
        for _ in range(length):
            buf.write(' ')
        return buf.getvalue()

    def writeArray(self, buf, arr, significantDigits, indent, dataType):
        """Write an n-dimensional array as JSON
        
        param buf
                   buffer for JSON
        param arr
                   array of data
        param significantDigits
                   number of significant digits
        param indent
                   number of indent spaces
        param dataType
                   array type
        param scaleFactor
                   the scale factor for this variable. (Set to 1 if there is no
                   scale factor.)
        param addOffset
                   the offset for this variable. (Set to 0 if there is no
                   offset.)
        throws Exception
        """
        # get the number of index positions in each dimension
        shape = arr.shape
        if len(shape) == 1:
            # if our shape length is 1, we have a 1-dimensional array, which is
            # easy to print
            buf.write(self.getIndentStr(indent) + "[ ")
            # create an index into the array
            for i in range(shape[0]):
                value = float(arr[i])
                buf.write(self.printValue(value, significantDigits))
                # print a ',' if appropriate
                if i != shape[0] - 1:
                    buf.write(", ")
            buf.write(" ]")
        else:
            # if we have higher dimensions, we need to call this print code on
            # each slice of this array
            buf.write(self.getIndentStr(indent) + "[\n")
            for i in range(shape[0]):
                # print a slice
                self.writeArray(buf, arr[i], significantDigits, indent + self.NUM_SPACES, dataType)
                # put a comma between slices
                if i != (shape[0] - 1):
                    buf.write(",\n")
                else:
                    buf.write("\n")
            buf.write(self.getIndentStr(indent) + "]")

    def printValue(self, value, significantDigits):
        """This function checks to see if value is a special number like NaN and
        then serializes to JSON appropriately.
        
        param value
                   the value to serialize
        param significantDigits
                   the number of digits for non-special values
        return json representation
        """
        if np.isnan(value) or np.isinf(value) or isinstance(value, np.ma.core.MaskedConstant):
            return "null"
        else:
            # Create the format string for float/double with the right number
            # of
            # significant digits
            doubleFormatStr = "%%.%dg" % significantDigits
            return doubleFormatStr % value

    def closeFile(self):
        """ Closes the netCDF file.
        
        throws IOException
        """
        self.file_.close()

def convert(netCdfFile, significantDigits):
    """Converts a netcdf file to json. See {@link NetCdfSerializer} for a
    description of the format of the netcdf file.
    
    param netCdfFile
              the location of the netcdf file
    param significantDigits
             the number of significant digits to print out
    return the json string
    throws IOException
    """
    obj = None
    res = None
    if not os.path.exists(netCdfFile):
        raise Exception("File does not exist: %s" % os.path.realpath(netCdfFile))
    try:
        obj = NetCdfSerializer(netCdfFile)
        res = obj.convertNotStatic(significantDigits)
    except Exception as e:
        sys.stderr.write(e)
    finally:
        try:
            obj.closeFile()
        except Exception:
            pass
    if res == None:
        exit(-1)
    return res

# The command should be called:
# 
# <pre>
# net_cdf_serializer.py  --file &ltfile&gt --significantDigits &ltnumber&gt
# </pre>
# 
# where <code>&ltfile&gt</code> is the location of the file to serialize
# and &ltnumber&gt is the number of significant digits to print out. The
# JSON will be written to STDOUT, unless an alternative stream handle is
# provided.

def main(args, output_stream=sys.stdout):
    description = """
    Visualize a netcdf map
    """
    parser = argparse.ArgumentParser(description=description)
    # "Usage: java gov.nasa.gsfc.giovanni.serializer.NetCdfSerializer --file file --significantDigits number"
    parser.add_argument("--file", type=str, help="Input NetCDF file", required=True)
    parser.add_argument("--significantDigits", type=int, help="Number of significant digits")
    args = parser.parse_args(args[1:])
    output_stream.write(convert(args.file, args.significantDigits))
    output_stream.flush()
    
if __name__ == '__main__':
    main(sys.argv)
