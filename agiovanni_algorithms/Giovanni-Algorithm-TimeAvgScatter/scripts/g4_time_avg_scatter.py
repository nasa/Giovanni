#!/bin/env python
"""Time Averaged Scatterplot for G4.

Calls the Perl module Giovanni::Algorithm::CorrelationWrapper to generate a temporal sum
and sample count for each grid point. Calling Perl is done by executing a temporary file
containing a three-line perl script. The remainer of the computation is done in Python,
in the clean_output() function.

See also: g4_time_avg_scatter_test.py (Unit Tests)
"""

__author__ = 'Daniel da Silva <Daniel.e.daSilva@nasa.gov>'

import optparse
import os
import string
import subprocess
import sys
import tempfile
import textwrap
from numpy import *

import netCDF4


def main(argv, stdout):
    """Main method of the application"""
    stdout.write('USER_MSG Computing time averaged scatterplot\n')
    stdout.flush()
    
    opts = parse_cli_args(argv)    
    sliced_fl = subset_vertical_slices(opts)

    try:
        matched_times = run_correlation(opts, sliced_fl)
        clean_output(opts, matched_times, sliced_fl)
    finally:
        if sliced_fl != opts.f:
            os.remove(sliced_fl)


def subset_vertical_slices(opts):
    """Generates new file list with zslices subsetted. No-op when no zslices.

    Return
      path to a file containing a file list (identical in form to -f value). If
      x or y variables do not requires zslicing, then pass those files through
      unmodified.
    """
    x_spec = VarSpec(opts.x)
    y_spec = VarSpec(opts.y)

    if x_spec.z_name is None and y_spec.z_name is None:
        return opts.f
    else:
        sliced_fl = tempfile.mkstemp()[1]
        fh = open(sliced_fl, 'w')
        
        for x_input, y_input in read_file_list(opts.f):
            if x_spec.z_name:
                x_sliced = copy_slice(x_input, x_spec)
            else:
                x_sliced = x_input

            if y_spec.z_name:
                y_sliced = copy_slice(y_input, y_spec)
            else:
                y_sliced = y_input
                    
            fh.write('%s %s\n' % (x_sliced, y_sliced))

        fh.close()
        return sliced_fl


def copy_slice(input_file, var_spec):
    """Copies the vertical subset into a new file and returns path to that file.

    Args
      input_file: path to granule
      var_spec: parsed opts.x or opts.y (see VarSpec)
    Returns
      path to file on file system containing z'th level of data
    """
    assert os.path.exists(input_file)
    
    if var_spec.z_name:
        sliced_file = os.path.join(os.path.dirname(input_file),
                                   'sliced.' + os.path.basename(input_file))        
        subprocess.check_call([
            'ncks',
            '-O', input_file, sliced_file,
            '-d', '%s,%.2f,%.2f' % (var_spec.z_name,
                                    var_spec.z_val - .001,
                                    var_spec.z_val + .001),
        ])

        assert os.path.exists(sliced_file)        
        return sliced_file
    else:
        return input_file


def run_correlation(opts, sliced_fl):
    """Call Perl code to calculate temporal sums and sample counts at each grid point.

    Args
      sliced_fl: path to file containing file list. This should only contain 2D data.
    Returns
      time coverage represented as tuple of ISO-8661 strings obtained from the
      first and last files.
    """
    assert os.path.exists(sliced_fl)

    perl_script = tempfile.NamedTemporaryFile()
    perl_script.write(textwrap.dedent("""#!/usr/bin/perl
    use Giovanni::Algorithm::CorrelationWrapper;
    Giovanni::Algorithm::CorrelationWrapper::run_correlation(@ARGV);
    print join(',', Giovanni::Algorithm::CorrelationWrapper::get_start_end_times($ARGV[0]));
    """));
    perl_script.flush()

    stdout_capture = tempfile.TemporaryFile()
    subprocess.check_call([
        'perl',    perl_script.name,
        sliced_fl, opts.o, opts.b,
        '1',       opts.x, opts.y        #  1 <=> verbose
    ], stdout=stdout_capture)
    perl_script.close()

    stdout_capture.seek(0)    
    start_time, end_time = stdout_capture.read().split(',')
    stdout_capture.close()
    
    assert start_time
    assert end_time
    assert os.path.exists(opts.o)

    return start_time, end_time


def clean_output(opts, matched_times, sliced_fl):
    """Processes the output of the CorrelationWrapper into its final form.
    
    Args
      matched_times: time coverage as tuple of ISO-8661 strings
      sliced_fl: path to file containing file list. This should contain only the
        2D data used.
    """
    assert os.path.exists(opts.o)
    assert os.path.exists(sliced_fl)

    x = VarSpec(opts.x)
    y = VarSpec(opts.y)
    x_name = 'x_' + x.var_name
    y_name = 'y_' + y.var_name
    dataset = netCDF4.Dataset(opts.o, 'a')

    # Derive time averages from sum_{d} and n_samples
    # (n_samples = 0) => masked value
    x_sum = dataset.variables['sum_x']    
    y_sum = dataset.variables['sum_y']
    x_var = dataset.createVariable(x_name, x_sum.dtype,
                                   dimensions=x_sum.dimensions,
                                   fill_value=x_sum._FillValue)
    y_var = dataset.createVariable(y_name, y_sum.dtype,
                                   dimensions=y_sum.dimensions,
                                   fill_value=y_sum._FillValue)    
    n_samples = dataset.variables['n_samples'][:]
    # This syntax is because x_var and x_sum are netcdf objs containing ndarrays
    # and n_samples is an ndarray: (and produces NaNs where n_samples[x,y] = 0
    x_var[:] = x_sum[:] / n_samples
    where_are_NaNs = isnan(x_var[:])
    #since this doesn't work: x_var[:][where_are_NaNs] = x_sum._FillValue;
    tmp = x_var[:]
    tmp[where_are_NaNs] = x_sum._FillValue
    x_var[:] = tmp
 
    y_var[:] = y_sum[:] / n_samples
    where_are_NaNs = isnan(y_var[:])
    #since this doesn't work: y_var[:][where_are_NaNs] = y_sum._FillValue;
    tmp = y_var[:]
    tmp[where_are_NaNs] = y_sum._FillValue
    y_var[:] = tmp
    
    # Copy variable/global attributes from sample files
    file_list = read_file_list(sliced_fl)
    xs_dataset = netCDF4.Dataset(file_list[0][0])
    xs_var = xs_dataset.variables[x.var_name]
    ys_dataset = netCDF4.Dataset(file_list[0][1])
    ys_var = ys_dataset.variables[y.var_name]

    for attr in xs_var.ncattrs():
        if attr != '_FillValue':
            x_var.setncattr(attr, xs_var.getncattr(attr))

    for attr in ys_var.ncattrs():
        if attr != '_FillValue':
            y_var.setncattr(attr, ys_var.getncattr(attr))            

    dataset.input_temporal_resolution = xs_dataset.temporal_resolution
    dataset.matched_start_time = matched_times[0]
    dataset.matched_end_time = matched_times[1]
    
    dataset.close()
    xs_dataset.close()
    ys_dataset.close()

    # Call NCO to remove variables
    subprocess.check_call([
        'ncks', '-O' , '-o', opts.o, '-x', '-v',
        'correlation,time_matched_difference,offset,slope,sum_x,sum_y,n_samples',
        opts.o
    ])

    # Call NCO to rename variables and dimensions
    subprocess.check_call([
        'ncrename',
        '-d', 'longitude,lon', '-v', 'longitude,lon',
        '-d', 'latitude,lat',  '-v', 'latitude,lat',
        '-O', opts.o, opts.o
    ])


def parse_cli_args(argv):
    """Parses command line arguments.
    
    Returns
       object that provides dot-access to options, ie opt.f <=> -f..
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
                      help="netCDF output filename")
    parser.add_option("-x", metavar="X_VAR_NAME", dest="x",
                      help="variable name in netCDF file to process")
    parser.add_option("-y", metavar="Y_VAR_NAME", dest="y",
                      help="variable name in netCDF file to process")
    parser.add_option("-z", metavar="Z-SLICE", dest="z",
                      help="dimension slize for 3D variables")
    parser.add_option("-l", metavar="LINEAGE_EXTRAS", dest="l",
                      help="lineage extras filename")
    parser.add_option("-S", metavar="SHAPEFILE", dest="S",
                      help="shapefile, in $shapefile/$shape format")
    parser.add_option("-j", metavar="JOBS", dest="j",
                      help="Number of Jobs run in parallel")


    return parser.parse_args(argv)[0]


def read_file_list(path):
    """Parses a file list file.
    
    Returns
      list of tuples, each tuple containing the paths to files grouped together.
    """
    assert os.path.exists(path)
    
    file_list = []
    
    with open(path) as fh:
        for line in fh:
            file_list.append(line[:-1].split(' '))

    return file_list


class VarSpec(object):
    """Parsed components of opt.x or opt.y"""
    def __init__(self, opt_val):
        if ',' in opt_val:
            self.var_name, tmp = opt_val.split(',')
            self.z_name, z_iden = tmp.split('=')
            self.z_val = ''.join(c for c in z_iden if c in string.digits)
            self.z_val = float(self.z_val)
            self.z_units = ''.join(c for c in z_iden if c not in string.digits)
        else:
            self.var_name = opt_val
            self.z_name = None
            self.z_val = None
            self.z_units = None

    
if __name__ == '__main__':
    main(sys.argv, sys.stdout)
