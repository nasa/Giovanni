#! /bin/env python
"""
####################################################################
NAME
g4_histogram.py - Calculate Histogram Data

DESCRIPTION
This generates a histogram dataset from data and time/space subset
info.

SYNOPSIS
Usage: g4_histogram.py [options]

OPTIONS
  -h, --help      show this help message and exit
  -s START_TIME   start time in ISO8601 format
  -e END_TIME     end time in IS08601 format
  -b BBOX         bounding box in 'W,S,E,N' format
  -f INPUT_FILE   an input file with a list of input files
  -o OUTPUT_FILE  The netCDF output filename
  -v VAR_NAME     variable name in netCDF file to process
  -z Z-SLICE      dimension slize for 3D variables
                
DEPENDENCY
netCDF4, numpy, isodate, psutil

AUTHORS
Daniel da Silva, 07/09/2014, Initial version

VERSION
$Revision: 1.22 $
####################################################################
"""

__author__ = 'Daniel da Silva <daniel.dasilva@nasa.gov>'

import math
import optparse
import os
import shutil
import subprocess
import sys
import tempfile
import time

import isodate
import psutil
import netCDF4 as nc
import numpy as np
import NcFile


class UiComm(object):
    """A collection of methods for communicating with the UI."""
    # Update progress every this many files
    UPDATE_PROGRESS_PER = 100
    # Holds whether or not to supress output
    _quiet = False
    log_scale_mode = False

    @classmethod
    def should_update(self, i):
        return i == 0 or (i + 1) % self.UPDATE_PROGRESS_PER == 0

    @classmethod
    def set_quiet(cls, value):
        cls._quiet = bool(value)

    @classmethod
    def user_info(cls, msg, stream=sys.stderr):
        """Reports status line to the user interface."""
        if not cls._quiet:
            print >> stream, 'USER_INFO ' + msg

    @classmethod
    def error(cls, msg, stream=sys.stderr):
        """Reports error line to the user interface."""
        if not cls._quiet:
            print >> stream, 'ERROR ' + msg

    @classmethod
    def debug(cls, msg, stream=sys.stderr):
        """Reports error line to the user interface."""
        if not cls._quiet:
            print >> stream, 'DEBUG ' + msg

    @classmethod
    def percent_done(cls, amount, stream=sys.stderr):
        """Reports percentage done to the user interface."""
        if not cls._quiet:
            print >> stream, 'PERCENT_DONE %d' % amount

class BaseFlow(object):
    """Base class for computation flows."""

    class Stats(object):
        """Struct-like class to hold computed statistics.

        The 'med' attribute is optional, may be None.
        """
        
        def __init__(self, total, num_fill, num_zeros, min_value, max_value, mean, std):
            self.total = total
            self.num_fill = num_fill
            self.num_zeros = num_zeros
            self.min_value = min_value
            self.max_value = max_value
            self.mean = mean
            self.std = std
            self.med = None
            
        def add_med(self, med):
            self.med = med

    def __init__(self, subsetted_file_names, options):
        self.subsetted_file_names = subsetted_file_names
        self.options = options

    def run(self):
        raise NotImplementedError

    def get_data(self, dataset, options):
        """Helper method to get the data stripped of fill values.

        
        Returns
          (data, num_fill), Data is 1-D Array with no fill values and num_fill
          is the number of fill values stripped out.
        Raises
          IndexError, num of variable dimensions is not 3 or 4.
          ValueError, invalid z-sclice was specified.
        """        
        variable = dataset.variables[options.v]

        # Manually handle vertical slices. The z-sclice is provided
        # by the -z option in the form: -z H2OPrsLvls_A=1000hPa
        # The first part is the name of the dimension, second
        # identifies which vertical slice we want.
        dims = variable.dimensions

        if len(dims) == 3:
            data = variable[:]        
        elif len(dims) == 4:
            z_name, z_value = options.z.split('=')
            z_dim = dataset.variables[z_name]
            z_value = z_value.replace(z_dim.units, '')
            z_value = float(z_value)
            z_pos = list(variable.dimensions).index(z_name)

            z_idx = -1
            epsilon = .001

            for i, z_tmp in enumerate(z_dim[:]):
                UiComm.debug(repr((z_tmp, z_value)))
                if abs(z_tmp - z_value) < epsilon:
                    z_idx = i
                    break

            if z_idx == -1:
                raise ValueError("Invalid z slice %s. Z dim is: %s"
                                 % (options.z, str(z_dim[:])))
            elif z_pos == 0:
                data = variable[z_idx, :, :, :]
            elif z_pos == 1:
                data = variable[:, z_idx, :, :]
            elif z_pos == 2:
                data = variable[:, :, z_idx, :]
            elif z_pos == 3:
                data = variable[:, :, :, z_idx]

            UiComm.debug("var.shape = " + repr(variable.shape))
            UiComm.debug("data.shape = " + repr(data.shape))
        else:
            raise IndexError("Invalid number of dims: %d" % len(dims))

        # We flatten everything to a numpy array and remove any fill
        # values to make future tasks simpler. At this point, `data`
        # may be a masked array or a normal array, so we handle both
        # cases.
        data_size = data.size
        if isinstance(data, np.ma.core.MaskedArray):
            num_fill = data_size - data.count()
        else:
            num_fill = 0
            
        num_zeros = 0
        if self.log_scale_mode:
            num_valids_before_log = data.size - np.isnan(data).sum()
            data = np.log10(data)
            data = np.ma.MaskedArray(data, np.in1d(data, [-np.inf, np.inf]))
        
        if isinstance(data, np.ma.core.MaskedArray):
            data = data.compressed()
            #num_fill = data_size - data.size
            if self.log_scale_mode:
                num_zeros = num_valids_before_log - data.size
        else:
            data = data.flatten()
            
        return data, num_fill, num_zeros

    def get_bin_edges(self, min_value, max_value):
        """Get the bin edges given a min and max value."""
        if self.log_scale_mode:
            #bins = 10 ** np.linspace(np.log10(min_value), np.log10(max_value), self.options.num_bins+1)
            bin_edges = np.logspace(min_value, max_value, self.options.num_bins + 1)
        else:
            bin_edges = np.linspace(min_value, max_value, self.options.num_bins + 1)
        
        return bin_edges

class InMemoryFlow(BaseFlow):
    """Computes histogram and statistics by loading all data into RAM"""

    def run(self):
        """Computes the histogram and statistics in memory.
    
        Returns
          (hist, bin_edges, stats)
        Raises
          ValueError, no data exists.
        """
        # Initialize bins
        hist = None
        bin_edges = None
        
        # Read all Data
        UiComm.user_info("Loading Data")
        
        try:
            all_data, num_fill, num_zeros = self.read_all_data()
        except IOError, e:
            UiComm.debug(str(e))
            UiComm.error("Internal Error #400")
            raise e
            
        UiComm.percent_done(40)

        #ZZZ
        #if all_data.size == 0:
        #    raise ValueError("No data exists")

        # Calculate the histogram
        UiComm.user_info("Binning")

        try:
            if all_data.size > 0:
              hist, bin_edges = self.calc_histogram(all_data)
        except IOError, e:
            UiComm.debug(str(e))
            UiComm.error("Internal Error #500")
            raise e
        
        UiComm.percent_done(60)
    
        # Calculate statistics
        UiComm.user_info("Computing statistics")
    
        try:
            stats = self.calc_stats(all_data, num_fill, num_zeros)
        except ValueError, e:
            UiComm.debug(str(e))
            UiComm.error("Internal Error #600")
            raise e
            
        return hist, bin_edges, stats

    def read_all_data(self):
        """
        Reads all data and returns as a single 1-D array.
    
        Returns
          all_data, 1-D array of all data with masked values dropped.
        Raises
          IOError, error opening one of the files.
        """
        file_arrays = []
        num_fill = 0
        num_zeros = 0        
        for i, file_name in enumerate(self.subsetted_file_names):
            if UiComm.should_update(i):
                UiComm.user_info("Reading data file %d of %d"
                                 % (i + 1, len(self.subsetted_file_names)))
            
            try:
                dataset = nc.Dataset(file_name)
            except Exception, e:
                raise IOError("Unable to open dataset " + file_name, e)
            
            data, cur_num_fill, cur_num_zeros = self.get_data(dataset, self.options)
            file_arrays.append(data)
            num_fill += cur_num_fill
            num_zeros += cur_num_zeros
            dataset.close()

        all_data = np.concatenate(file_arrays)

        return all_data, num_fill, num_zeros
    
    def calc_histogram(self, all_data):
        """Calculate a histogram of the data.
        
        Returns
          (hist, bin_edges), hist the values of the histogram. bin_edges is
          a list of size (num_bins + 1) that contains the edges of each bin.
        """
        return np.histogram(all_data, bins=self.options.num_bins)

    def calc_stats(self, all_data, num_fill, num_zeros):
        """Calculate statistics of the data.
    
        Returns
            instance of Stats class that holds several statistics.
        """
        # The standard deviation is explicitly calculated with
        # float64 due to its nature to overflow.
        data_std = None if all_data.size == 0 else np.std(all_data, dtype=np.float64)
        data_med = None if all_data.size == 0 else np.median(all_data)
        data_min = None if all_data.size == 0 else all_data.min()
        data_max = None if all_data.size == 0 else all_data.max()
        data_mean = None if all_data.size == 0 else all_data.mean()
        
        stats = self.Stats(all_data.size,
                           num_fill,
                           num_zeros,
                           data_min,
                           data_max,
                           data_mean,
                           data_std)
        stats.add_med(data_med)

        return stats


class RollingFlow(BaseFlow):
    """Computes histogram and statistics using rolling algorithms."""    

    class FirstPassResults(object):
        def __init__(self, min_value, max_value, sum_, size, num_fill, num_zeros):
            self.min_value = min_value
            self.max_value = max_value
            self.sum_ = sum_
            self.size = size
            self.num_fill = num_fill
            self.num_zeros = num_zeros

    class SecondPassResults(object):
        def __init__(self, hist, bin_edges, mean, std):
            self.hist = hist
            self.bin_edges = bin_edges
            self.mean = mean
            self.std = std

    def run(self):
        """Computes the histogram and statistics using rolling algorithms.
    
        Returns
          (hist, bin_edges, stats)
        Raises
          ValueError, no data exists.
        """
        first_pass_results = self.first_pass()
        second_pass_results = self.second_pass(first_pass_results)

        hist = second_pass_results.hist
        bin_edges = second_pass_results.bin_edges
        stats = self.Stats(first_pass_results.size,
                           first_pass_results.num_fill,
                           first_pass_results.num_zeros,
                           first_pass_results.min_value,
                           first_pass_results.max_value,
                           second_pass_results.mean,
                           second_pass_results.std)            
        
        return (hist, bin_edges, stats)


    def first_pass(self):
        """First pass of the data.
        
        Returns
          an instance of FirstPassResults
        Raises
          ValueError, all data was empty.
          IOError, error opening one of the files.
        """
        min_value = None
        max_value = None
        unset = True

        sum_ = 0
        size = 0
        num_fill = 0
        num_zeros = 0

        for i, file_name in enumerate(self.subsetted_file_names):
            if UiComm.should_update(i):
                UiComm.user_info("Performing first pass of data %d of %d"
                                 % (i + 1, len(self.subsetted_file_names)))
            
            try:
                dataset = nc.Dataset(file_name)
            except Exception, e:
                raise IOError("Unable to open dataset " + file_name, e)
            
            data, cur_num_fill, cur_num_zeros = self.get_data(dataset, self.options)

            if len(data) > 0:
                sum_ += data.sum()
                size += len(data)

                if unset:
                    min_value = data.min()
                    max_value = data.max()
                    unset = False
                else:
                    min_value = min(min_value, data.min())
                    max_value = max(max_value, data.max())

            num_fill += cur_num_fill
            num_zeros += cur_num_zeros

            dataset.close()

        if unset:
            raise ValueError("Data is empty")
        
        return self.FirstPassResults(min_value,
                                     max_value,
                                     sum_,
                                     size,
                                     num_fill,
                                     num_zeros)

    def second_pass(self, first_pass_results):
        """Second pass of the data.
        
        Returns
          an instance of SecondPassResults
        Raises
          ValueError, all data was empty
          IOError, error opening one of the files.
        """
        hist = [0 for _ in range(self.options.num_bins)]
        bin_edges = self.get_bin_edges(first_pass_results.min_value,
                                       first_pass_results.max_value)

        mean = float(first_pass_results.sum_) / first_pass_results.size
        std = 0

        # O(N*M), N = data and M = number of bins
        for i, file_name in enumerate(self.subsetted_file_names):
            if UiComm.should_update(i):
                UiComm.user_info("Performing second pass of data %d of %d"
                                 % (i + 1, len(self.subsetted_file_names)))
    
            try:
                dataset = nc.Dataset(file_name)
            except Exception, e:
                raise IOError("Unable to open dataset " + file_name, e)

            data, _, _ = self.get_data(dataset, self.options)
            std += ((data - mean)**2).sum()
            
            for i in range(self.options.num_bins):
                bin_left = bin_edges[i]
                bin_right = bin_edges[i + 1]

                if i == (self.options.num_bins - 1):
                    in_range = (data >= bin_left) & (data <= bin_right)
                else:
                    in_range = (data >= bin_left) & (data <  bin_right)

                hist[i] += in_range.sum()

        std /= first_pass_results.size - 1
        std = math.sqrt(std)
        
        return self.SecondPassResults(hist, bin_edges, mean, std)


def iso8601_to_epoch(iso_time):
    """Converts an ISO8601 DateTime String to an Epoch Timestamp
    
    Raises
      ValueError, invalid ISO time
    """
    iso_time = iso_time.replace(' ', '')

    try:
        date_time = isodate.parse_datetime(iso_time)        
    except isodate.ISO8601Error, e:
        raise ValueError("Invalid ISO Time", e)

    epoch = time.mktime(date_time.timetuple())
    
    return epoch


def parse_cli_args(args):
    """Parses command line arguments.

    Returns
      options, an object whose attributes match the values of the
      specified in the command line. e.g. '-e xyz' <=> options.e
    Raises
      OptionError, error parsing options
      ValueError, invalid or missing argument      
    """
    parser = optparse.OptionParser()

    parser.add_option("-s", metavar="START_TIME", dest="s",
                      help="start time in ISO8601 format")
    parser.add_option("-e", metavar="END_TIME", dest="e",
                      help="end time in IS08601 format")
    parser.add_option("-b", metavar="BBOX", dest="b",
                      help="bounding box in 'W,S,E,N' format")
    parser.add_option("-f", metavar="INPUT_FILE", dest="f",
                      help="an input file with a list of input files")
    parser.add_option("-o", metavar="OUTPUT_FILE", dest="o",
                      help="The netCDF output filename")
    parser.add_option("-v", metavar="VAR_NAME", dest="v",
                      help="variable name in netCDF file to process")
    parser.add_option("-z", metavar="Z-SLICE", dest="z",
                      help="dimension slize for 3D variables")
    parser.add_option("-l", metavar="LINEAGE_EXTRAS", dest="l",
                      help="lineage extras filename")
    parser.add_option("-S", metavar="SHAPEFILE", dest="S",
                      help="Shapefile, in $shapefile/$shape format")
    parser.add_option("-j", metavar="JOBS", dest="j",
                      help="Number of Jobs run in parallel")

    options, _ = parser.parse_args(args)

    # Verify required are present and not empty
    required_opts = 'sebfov'

    for required_opt in required_opts:
        if not getattr(options, required_opt, None):
            raise ValueError("-%s missing" % required_opt)
        
    # Validate start and end time
    try:
        iso8601_to_epoch(options.s)
    except ValueError, e:
        raise ValueError("-s is not in ISO_8601 format", e)

    try:
        iso8601_to_epoch(options.e)
    except ValueError, e:
        raise ValueError("-e is not in ISO_8601 format", e)

    # Validate bbox
    toks = options.b.split(',')

    if len(toks) != 4:
        raise ValueError("-b has invalid format")

    for tok in toks:
        try:
            float(tok)
        except ValueError:
            raise ValueError("-b has invalid format")

    # Set num_bins manually, placeholder for when this is retrieved
    # from the workflow
    setattr(options, 'num_bins', 50)

    # Return
    return options


def read_input_file_names(input_list_file, dir_name):
    """Extract the input datasets from the -f input file.
    
    Returns
      input_file_names, a list of file names     
    """
    input_file_names = []

    for line in input_list_file.readlines():
        stripped_line = line.strip()
        if stripped_line:
            file_name = os.path.join(dir_name, stripped_line)
            input_file_names.append(file_name)
    
    return input_file_names


def subset_files(input_file_names, options, temp_dir):
    """
    Spatially and temporally subset a set of files according to the given
    command line options.

    Returns
      subsetted_file_names, a list of file names that contain only the
      subsetted data.
    Raises
      RuntimeError, error calling NCO.
    """
    subsetted_file_names = []


    for i, input_file_name in enumerate(input_file_names):
        if UiComm.should_update(i):        
            UiComm.user_info("Subsetting %d of %d"
                             % (i + 1, len(input_file_names)))
        
        # Add 'subsetted.' before file name for the subsetted file name
        base_name = 'subsetted.' + os.path.basename(input_file_name)
        subsetted_file_name = os.path.join(temp_dir, base_name)
        subsetted_file_names.append(subsetted_file_name)

        # First snap to point if necessary
        # Call NCO command line to preform subsetting operation
        bbox = [float(f) for f in options.b.split(',')]

        args = [
            'ncea',
            '-d', 'lat,%.2f,%.2f' % (bbox[1], bbox[3]),
            '-d', 'lon,%.2f,%.2f' % (bbox[0], bbox[2]),
            '-v', options.v,
            input_file_name,
            subsetted_file_name,            
        ]

        UiComm.debug('Running: ' + str(args))

        try:
            nco_proc = subprocess.Popen(args,
                                        stdout=subprocess.PIPE,
                                        stderr=subprocess.PIPE)
        except OSError, e:
            raise RuntimeError("NCO Popen Failed", e)
        
        while True:
            stdout, stderr = nco_proc.communicate()
            
            for line in stdout.splitlines():
                UiComm.debug(line)

            for line in stderr.splitlines():
                UiComm.debug(line)

            if nco_proc.poll() is not None:
                break

        if nco_proc.returncode != 0:
            raise RuntimeError("NCO exited with nonzero returncode")

    return subsetted_file_names


# Since histogram subsets and averages in one step, we want to do a
# subset and find out what nco did and then report that. So 
# This is sort of a dry-run of ncea/ncks to determine what bbox was used
# for the histogram (actual grid can very from user's bounding box)
def dry_run_to_determine_final_spatial_gridinfo(bbox,filename):

    bbox_array = bbox.split(',')
    output_file = filename + '.dryrun'
   
   
    cmd = 'ncks -d lon,' + bbox_array[0] + ',' + bbox_array[2] \
        + ' -d lat,'     + bbox_array[1] + ',' + bbox_array[3] \
        + " " + filename  \
        + " " + output_file 

    UiComm.debug('Running: ' + str(cmd))

    try:
        nco_proc = subprocess.Popen(cmd,
                                    stdout=subprocess.PIPE,
                                    stderr=subprocess.PIPE,
                                    shell=True)
    except OSError, e:
        raise RuntimeError("NCO Popen Failed", e)

    while True:
        stdout, stderr = nco_proc.communicate()

        for line in stdout.splitlines():
            UiComm.debug(line)

        for line in stderr.splitlines():
            UiComm.debug(line)

        if nco_proc.poll() is not None:
            break

    if nco_proc.returncode != 0:
        raise RuntimeError("NCO exited with nonzero returncode")
     
    try:
        dataset = nc.Dataset(output_file)
    except Exception, e:
        raise IOError("Unable to open dataset " + output_file, e)

    # Get gridinfo:

    REPORT_GRID = {}
    try:
        lon = (dataset.variables['lon'][0], dataset.variables['lon'][-1])
        lat = (dataset.variables['lat'][0], dataset.variables['lat'][-1])
        REPORT_GRID['lon'] = lon 
        REPORT_GRID['lat'] = lat 
        
    except IOError:
        UiComm.debug(str(e))
        UiComm.error("Internal Error #700")
        raise e

    os.remove(output_file)
    return REPORT_GRID;

    
def get_sum_file_sizes(file_names):
    """Sums the sizes of a list of files.
    
    Returns
      sum of file sizes in bytes
    """
    return sum(os.stat(file_name).st_size for file_name in file_names)


def read_attributes(file_name, options):
    """Read attributes of a variable from a dataset.
    
    Returns
      dictionary of attribute names and values
    Raises
      IOError, error opening the dataset
    """
    try:
        dataset = nc.Dataset(file_name)
    except Exception, e:
        raise IOError("Unable to open dataset " + file_name, e)

    variable = dataset.variables[options.v]

    attribs = {}

    for attrib_name in variable.ncattrs():
        attribs[attrib_name] = variable.getncattr(attrib_name)

    dataset.close()

    return attribs

def write_gridinfo(output_file,gridinfo):
  dataset = nc.Dataset(output_file, "a", format="NETCDF4_CLASSIC")
  dataset.geospatial_lon_min = gridinfo['lon'][0]
  dataset.geospatial_lon_max = gridinfo['lon'][1]
  dataset.geospatial_lat_min = gridinfo['lat'][0]
  dataset.geospatial_lat_max = gridinfo['lat'][1]
  dataset.close()

def write_histogram(hist, bin_edges, stats, hist_log, bin_edges_log, stats_log, attribs, options):
    """Writes out histogram dataset"""
    n = options.num_bins
    dataset = nc.Dataset(options.o, "w", format="NETCDF4_CLASSIC")
    hist_arr = [hist, hist_log]
    stats_arr = [stats, stats_log]
    bin_edges_arr = [bin_edges, bin_edges_log]
    title_arr = ['','_log']
    
    for log_mode in [0,1]:
        # bin_left: dimension, variable
        if bin_edges_arr[log_mode] == None:
    	    if log_mode == 0:
                # Exit if we found no data in regular mode.
                # We don't want to exit if there is no log-data
                # but the regular data is still present (e.g.
                # when all data are negatives)
                UiComm.user_info("No data found")
                sys.exit(1)
            else:
                continue
            # We can create an empty variable, but some tools might not like this.
            # dataset.createDimension('bin_left'+title_arr[log_mode])
            # variable_bins = dataset.createVariable('bin_left'+title_arr[log_mode], 'f', ('bin_left'+title_arr[log_mode],)) 
            # variable_bins[:] = []
            # variable_hist = dataset.createVariable(options.v+title_arr[log_mode], 'i', ('bin_left'+title_arr[log_mode],))
            # variable_hist[:] = []
        else:
            dataset.createDimension('bin_left'+title_arr[log_mode], size=n)
            variable_bins = dataset.createVariable('bin_left'+title_arr[log_mode], 'f', ('bin_left'+title_arr[log_mode],))
            variable_bins[:] = bin_edges_arr[log_mode][:-1]
            variable_hist = dataset.createVariable(options.v+title_arr[log_mode], 'i', ('bin_left'+title_arr[log_mode],))
            variable_hist[:] = [0]*n if  hist_arr[log_mode] == None else hist_arr[log_mode]

        variable_bins.units = attribs['units']
        
        # hist: variable
        
    
        for attrib_name, attrib_value in attribs.iteritems():
            if attrib_name != '_FillValue':
                variable_hist.setncattr(attrib_name, attrib_value)

        variable_hist.total = stats_arr[log_mode].total
        variable_hist.num_fill = stats_arr[log_mode].num_fill
        if stats_arr[log_mode].num_zeros != None and log_mode == 1: variable_hist.num_zeros = stats_arr[log_mode].num_zeros
        if stats_arr[log_mode].min_value != None: variable_hist.min = stats_arr[log_mode].min_value
        if stats_arr[log_mode].max_value != None: variable_hist.max = stats_arr[log_mode].max_value
        if stats_arr[log_mode].mean != None: variable_hist.mean = stats_arr[log_mode].mean
        if stats_arr[log_mode].std != None: variable_hist.std = stats_arr[log_mode].std

        if stats_arr[log_mode].med is not None: variable_hist.med = stats_arr[log_mode].med

    dataset.close()

    
def main(argv, flow_override=None):
    """
    The main procedure of this script is essentially a sequence of
    stages modelled as functions, where the output of one function
    is attached to the input to the next. Error handling is
    exception-based and is checked at each stage.

    There is one branch case, which determines whether to read all
    data at once or to perform multiple passes. The two cases are
    implemented as subclasses of BaseFlow, with compatible APIs.

    Args
      flow_override, override the flow to use (for testing)

            +------------------+                       
            | O V E R V I E W  |                       
            +------------------+                       
                                                             
             parse_cli_args()                         
                                                  
             read_input_file_names()                  
                                                  
             subset_files()                           
                     +                                
                     |            In memory if can load into RAM,
             +-------+--------+   rolling flow otherwise.
             |                |                       
             v                v                       
        IN MEMORY FLOW     ROLLING FLOW               
                                                      
         read_all_data()    first_pass()
                                                      
         calc_histogram()   second_pass()
                              +                       
         calc_stats()         |                       
             +                |                       
             |                |                       
             +-------+--------+                       
                     |                               
                     |                               
                     v
             read_attributes()                       
                                                      
             write_histogram()    
    """
    # Parse command line arguments
    try:
        options = parse_cli_args(argv[1:])
    except optparse.OptionError, e:
        UiComm.debug(str(e))
        UiComm.error("Internal Error #100")
        raise e
    except ValueError, e:
        UiComm.debug(str(e))
        UiComm.error("Internal Error #101")
        raise e

    UiComm.percent_done(0)
    
    # Create temp dir
    temp_dir = tempfile.mkdtemp()

    # Retrieve list of individual files
    try:
        input_list_file = open(options.f)
    except IOError, e:
        UiComm.debug(str(e))
        UiComm.error("Internal Error #200")
        raise e

    dir_name = os.path.dirname(options.f)
    input_file_names = read_input_file_names(input_list_file,
                                             dir_name)
    input_list_file.close()

    # Snap to point for NCO if too small
    # This also converts options.b to float for any later NCO operations:
    testNc = NcFile.NcFile(input_file_names[0]) 
    options.b = testNc.subset_bbox_cmd_pyver(options.b) 

    # Get datagrid before averaged out:
    report_grid = dry_run_to_determine_final_spatial_gridinfo(options.b,input_file_names[0])

    # Subset input files
    try:
        subsetted_file_names = subset_files(input_file_names,
                                            options,
                                            temp_dir)
    except RuntimeError, e:
        UiComm.debug(str(e))
        UiComm.error("Internal Error #300")
        raise e

    UiComm.percent_done(30)

    # Branch based on whether all data can be read into memory at once.
    # This is determined by whether the total size of the subsetted
    # files is greater than 1/2 the available memory on the system.
    total_size = get_sum_file_sizes(subsetted_file_names)
    free_mem = psutil.virtual_memory().free
    
    if flow_override is not None:
        UiComm.debug("flow decision is overrided: ")
        UiComm.debug(str(flow_override))
        flow = flow_override(subsetted_file_names, options)
    elif free_mem > 2 * total_size:
        UiComm.debug("flow is: InMemoryFlow")
        flow = InMemoryFlow(subsetted_file_names, options)
    else:
        UiComm.debug("flow is: RollingFlow")
        flow = RollingFlow(subsetted_file_names, options)

    
    flow.log_scale_mode = False
    hist, bin_edges, stats = flow.run()
    UiComm.percent_done(50)
    
    flow.log_scale_mode = True
    hist_log, bin_edges_log, stats_log = flow.run()
    UiComm.percent_done(80)
    
    # Read attributes of variable
    try:
        attribs = read_attributes(input_file_names[0], options)
    except IOError:
        UiComm.debug(str(e))
        UiComm.error("Internal Error #700")
        raise e

    # Write histogram
    UiComm.user_info("Writing histogram data")
    write_histogram(hist, bin_edges, stats, hist_log, bin_edges_log, stats_log, attribs, options)
    UiComm.percent_done(95)

    write_gridinfo(options.o,report_grid)

    # Cleanup temp files
    UiComm.user_info("Deleting temp files")
    shutil.rmtree(temp_dir)
    UiComm.percent_done(100)


if __name__ == '__main__':
    main(sys.argv)

