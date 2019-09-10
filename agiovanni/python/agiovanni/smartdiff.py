'''
Tools for doing a smart diff between netcdf files. The diff ignores the order
of variables and attributes.

@author: csmit
'''
import tempfile
import shutil
import os
from netCDF4 import Dataset
import subprocess
import difflib


class DiffException(Exception):
    """
    Used to indicate something went wrong with one of the functions in this
    module.
    """
    pass


def diff_nc(first, second, ignore_nco=True, ignore={}):
    """
    Diffs two netcdf files using cdl. Variables and attributes are sorted so
    order doesn't matter.

    INPUTS:
    first - first file to compare
    second - second file to compare
    ignore_nco - ignore NCO metadata (history, NCO version, etc.) if present.
        Defaults to True.
    ignore - dict of variables to attributes to ignore. For global attributes
        use the '' key. E.g. -
        {'':('plot_hint_caption'),'var1':('units','long_name')}
        will ignore the global attribute 'plot_hint_caption' and var1's
        'units' and 'long_name' attributes.

    OUTPUTS:
    diff - a string with the differences. Empty if files are the same.
    """
    tempdir = tempfile.mkdtemp("DIFF_NC")

    # sort the netcdf files first...
    f1 = os.path.join(tempdir, "%s_sorted1.nc" % os.path.basename(first))
    sort_nc(first, f1, remove_nco=ignore_nco, remove=ignore)
    f2 = os.path.join(tempdir, "%s_sorted2.nc" % os.path.basename(second))
    sort_nc(second, f2, remove_nco=ignore_nco, remove=ignore)

    # dump to cdl
    cdl1 = dump_to_cdl(f1)
    cdl2 = dump_to_cdl(f2)

    # replace the first line because it has the filename
    cdl1[0] = "netcdf FILENAME {"
    cdl2[0] = "netcdf FILENAME {"

    df = difflib.context_diff(cdl1, cdl2, first, second)
    diff_out = []
    for line in df:
        diff_out.append(line)

    return diff_out


def dump_to_cdl(in_file, command_line_options=[]):
    """
    Dump a netcdf file to CDL.

    INPUTS:
    in_file - input netcdf file
    command_line_options - extra command line options to change cdl output

    OUTPUT:
    out - array of lines of CDL
    """
    cmd = ["ncdump %s" % in_file]
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    out = p.communicate()[0]
    if p.returncode == 0:
        return out.splitlines()
    else:
        raise DiffException("Unable to run command: %s" % " ".join(cmd))


def sort_nc(in_nc_file, out_nc_file, remove_nco=True, remove={}):
    """
    Sorts a netcdf file so variables and attributes appear in alphabetical
    order. Note: _FillValue attributes will be the first attribute rather than
    in alphabetical order.

    INPUTS:
    in_nc_file - input netcdf file
    out_nc_file - file for sorted netcdf
    remove_nco - don't copy over the NCO global metadata (history, NCO, etc.).
        Default to True.
    remove - dict of attributes to remove. E.g. -
        {'':('plot_hint_caption'),'var1':('units','long_name')}
        will ignore the global attribute 'plot_hint_caption' and var1's
        'units' and 'long_name' attributes.
    """
    needs_tempfile = os.path.exists(
        out_nc_file) and os.path.samefile(in_nc_file, out_nc_file)

    if needs_tempfile:
        (h, output_for_now) = tempfile.mkstemp("nc")
        os.close(h)
    else:
        output_for_now = out_nc_file
    in_nc = Dataset(in_nc_file, 'r')
    out_nc = Dataset(output_for_now, 'w', format=in_nc.data_model)

    # first create dimensions
    dim_names = sorted(in_nc.dimensions.keys())
    for dim_name in dim_names:
        if in_nc.dimensions[dim_name].isunlimited():
            out_nc.createDimension(dim_name)
        else:
            out_nc.createDimension(
                dim_name,
                size=len(
                    in_nc.dimensions[dim_name]))

    # now variables
    var_names = sorted(in_nc.variables.keys())
    for var_name in var_names:
        if var_name in remove:
            _copy_var(var_name, in_nc, out_nc, remove[var_name])
        else:
            _copy_var(var_name, in_nc, out_nc)

    # global attributes
    attributes = sorted(in_nc.ncattrs())

    if remove_nco:
        # get rid of NCO-related metadata
        attributes_to_remove = ('history', 'history_of_appended_files', 'NCO',
                                'nco_input_file_list', 'nco_input_file_number',
                                'nco_openmp_thread_number')

        for att in attributes_to_remove:
            if att in attributes:
                attributes.remove(att)

    if '' in remove:
        # global attributes to remove
        for att in remove['']:
            if att in attributes:
                attributes.remove(att)

    for att in attributes:
        out_nc.setncattr(att, in_nc.getncattr(att))

    out_nc.close()
    in_nc.close()

    if needs_tempfile:
        shutil.move(output_for_now, out_nc_file)


def _copy_var(var_name, in_nc, out_nc, attributes_to_ignore=[]):
    """
    Copies a variable from one netcdf file to another, sorting the attributes.
    Args:
        var_name: name of variable
        in_nc: input Dataset object
        out_nc: output Dataset object
        attributes_to_ignore: list or tuple of attributes not to copy over

    Returns:

    """
    old_var = in_nc[var_name]

    # create new variables
    if '_FillValue' in old_var.ncattrs() and \
            '_FillValue' not in attributes_to_ignore:
        new_var = out_nc.createVariable(
            var_name,
            old_var.datatype,
            old_var.dimensions,
            fill_value=old_var._FillValue)
        attributes = old_var.ncattrs()
        attributes.remove('_FillValue')
    else:
        new_var = out_nc.createVariable(
            var_name,
            old_var.datatype,
            old_var.dimensions)
        attributes = old_var.ncattrs()

    # copy over the data
    new_var[:] = old_var[:]

    # sort the attributes
    attributes.sort()
    # set the attributes
    for att in attributes:
        if att not in attributes_to_ignore:
            new_var.setncattr(att, old_var.getncattr(att))
