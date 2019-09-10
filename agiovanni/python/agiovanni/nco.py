"""
A collection of functionality for utilizing the NCO toolset.
"""
__author__ = 'Daniel da Silva <Daniel.daSilva@nasa.gov>'

import subprocess
import sys


class NCOError(Exception):

    """An exception thrown when an NCO call returns a non-zero status.

    Attributes
      return_code, int containing the NCO return code.
    """

    def __init__(self, return_code):
        self.return_code = return_code

    def __repr__(self):
        return 'NCOError(%d)' % self.return_code


class NCOCommandNotFound(NCOError):

    """An exception thrown when an NCO executable is not found.

    Attributes
      command_name
    """

    def __init__(self, command_name):
        self.command_name = command_name

    def __repr__(self):
        return 'NCOCommandNotFound(%s)' % repr(self.command_name)

    def __str__(self):
        return 'Missing command %s' % repr(self.command_name)


def _perform_call(argv, **kwargs):
    """Perform an NCO call. Implements global keyword arguments.

    Supported kwargs:
      overwrite, set to True to overwrite an existing file
      suppress_hist, set to True to suppress writing to the history attribute
      stdout, specify alternative to sys.stdout
      stderr, specify alternative to sys.stderr
    Raises:
      NCOError, the NCO call returned a non-zero exit code
    """
    stdout = kwargs.get('stdout', sys.stdout)
    stderr = kwargs.get('stderr', sys.stderr)

    if kwargs.get('overwrite'):
        argv.append('-O')

    if kwargs.get('suppress_hist'):
        argv.append('-h')

    try:
        return_code = subprocess.call(argv, stdout=stdout, stderr=stderr)
    except OSError, e:
        if e.errno == 2:
            raise NCOCommandNotFound(argv[0])
        else:
            raise e

    if return_code != 0:
        raise NCOError(return_code)


def subset(source, dest, bounds, **kwargs):
    """Subset the contents of an NetCDF file.

    The subsetted result is written to dest.

    Args
       source, the file path of the original NetCDF file
       dest, the file path of the output NetCDF file
       bounds, agiovanni.geo.Bounds instance
    Raises
       NCOError, the NCO call returned a non-zero status
    """
    argv = [
        'ncks',
        '-d', 'lat,%.6f,%.6f' % (bounds.south, bounds.north),
        '-d', 'lon,%.6f,%.6f' % (bounds.west, bounds.east),
        source,
        dest,
    ]
    _perform_call(argv, **kwargs)


def run_script(script_path, source, dest, **kwargs):
    """Run an NCO script.

    Args
      script_path, the path to the script on the system
      source, the NetCDF input file path on the system
      dest, the NetCDF output file path on the system
    Raises
      NCOError, the NCO call returned a non-zero status
    """
    argv = [
        'ncap2',
        '-v',
        '-S', script_path,
        source,
        dest,
    ]

    _perform_call(argv, **kwargs)


def inline_script(inline_code, source, dest, **kwargs):
    """Run an inline NCO script.

    Args
      inline_code, the inline code to run
      source, the path to the NetCDF input file
      dest, the path to the NetCDF output file
    Raises
      NCOError, the NCO call returned a non-zero status
    """
    argv = [
        'ncap2',
        '-s', inline_code,
        source,
        '-o', dest
    ]

    _perform_call(argv, **kwargs)


def average(source, dest, dims, **kwargs):
    """Average along one or more dimensions.

    Args
      source, path to the input NetCDF file to average
      dest, path to a NetCDF file to output
      dims, string or tuple of strings. dimensions to
        average over.
    Raises
      NCOError, the NCO call returned a non-zero status
    """
    if isinstance(dims, (list, tuple)):
        dims = ','.join(dims)

    argv = [
        'ncwa',
        '-a', dims,
        source,
        dest
    ]

    _perform_call(argv, **kwargs)


def remove_vars(source, dest, vars_, **kwargs):
    """Remove variables from a NetCDF file.

    Args
      source, the input NetCDF file
      dest, the output NetCDF file
      vars_, string or tuple of stirngs. Names of variables    
    Raises
      NCOError, an error occurred during the NCO call
    """
    if isinstance(vars_, (list, tuple)):
        vars_ = ','.join(vars_)

    argv = [
        'ncks',
        '-x',
        '-v', vars_,
        source,
        dest,
    ]

    _perform_call(argv, **kwargs)


def remove_dims(source, dest, dims, **kwargs):
    """Remove dimensions from a NetCDF file.

    Args
      source, the input NetCDF file
      dest, the output NetCDF file
      dims, a string or tuple of strings. Names of dimensions to
        remove.
    Raises
      NCOError, an error occurred during the NCO call
    """
    if isinstance(dims, (list, tuple)):
        dims = ','.join(dims)

    argv = [
        'ncks',
        '-x',
        '-v', dims,
        source,
        dest,
    ]

    _perform_call(argv, **kwargs)


def rename_vars(source, dest, names, **kwargs):
    """Rename variables in an NetCDF file.

    Args:
      source, the input NetCDF file
      dest, the output NetCDF file
      names, a dictionary of old names to new names
    Raises
      NCOError, an error occurred during the NCO call
    """
    argv = [
        'ncrename',
        source,
        dest,
    ]

    for item in names.iteritems():
        argv.extend(['-v', '%s,%s' % item, ])

    _perform_call(argv, **kwargs)


def delete_history(source, dest, **kwargs):
    kwargs['suppress_hist'] = True
    delete_attributes(source, dest, [{'att_name': 'history'}], **kwargs)


def edit_attributes(source, dest, attributes, **kwargs):
    """Delete attributes in a NetCDF file.

    Args:
      source, the input NetCDF file
      dest, the output NetCDF file
      attributes, a list of dicts with information about which attributes to
        edit. Each dict should have 'att_name','var_name','att_type',
        'att_val'. If no there is no 'var_name' in the dict, the code will 
        assume this is a global attribute.
        E.g. - 
        [{'att_name':'units','var_name':'my_variable','att_type','c','1'}]

        The 'att_type' can be any of the nco types. Refer to the user manual
        for all of them, but the most common are:
        f - float
        d - double
        i - integer
        c - char

    Raises
      NCOError, an error occurred during the NCO call

    """
    argv = [
        'ncatted',
        source,
        dest,
    ]

    for attribute in attributes:
        var_name = attribute.get('var_name', 'global')
        argv.extend(['-a', '%s,%s,o,%s,%s'
                     % (attribute['att_name'], var_name, attribute['att_type'],
                        attribute['att_val'])])

    _perform_call(argv, **kwargs)


def delete_attributes(source, dest, attributes, **kwargs):
    """Delete attributes in a NetCDF file.

    Args:
      source, the input NetCDF file
      dest, the output NetCDF file
      attributes, a list of dicts with information about which attributes to
        edit. Each dict should have 'att_name','var_name'. If no there is no
        'var_name' in the dict, the code will assume this is a global attribute.
        E.g. - 
        [{'att_name':'units','var_name':'my_variable'},
         {'att_name':'history'}

    Raises
      NCOError, an error occurred during the NCO call

    """
    argv = [
        'ncatted',
        source,
        dest,
    ]

    for attribute in attributes:
        var_name = attribute.get('var_name', 'global')
        argv.extend(['-a', '%s,%s,d,,' % (attribute['att_name'], var_name)])

    _perform_call(argv, **kwargs)


def rename_dims(source, dest, names, rename_vars=False, **kwargs):
    """Rename dimensions in an NetCDF file.

    Args:
      source, the input NetCDF file
      dest, the output NetCDF file
      names: a dictionary of old names to new names
      rename_vars: rename coordinate variables as well
    Raises
      NCOError, an error occurred during the NCO call
    """
    argv = [
        'ncrename',
        source,
        dest,
    ]

    for item in names.iteritems():
        argv.extend(['-d', '%s,%s' % item, ])
        if rename_vars:
            argv.extend(['-v', '%s,%s' % item, ])

    _perform_call(argv, **kwargs)
