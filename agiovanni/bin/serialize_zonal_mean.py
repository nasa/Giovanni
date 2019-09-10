#! /bin/env python

import sys
import argparse
import os
import re
from lxml import etree
import urlparse
import urllib
import numpy as np
from netCDF4 import Dataset


def main(argv, stdout):
    """
    Main function. Called:
       serialize_zonal_mean  /path/to/input.xml  /path/to/zonal.nc /path/to/working/directory
    Prints out the name of the csv file created to stdout.
    """

    description = """
    Provide a .csv output for zonal mean files
    """
    parser = argparse.ArgumentParser(description=description)

    parser.add_argument(
        "input", type=str, help="location of input.xml file for session")
    parser.add_argument(
        "nc_file", type=str, help="location of netcdf file to serialize")
    parser.add_argument("working_dir", type=str, help="working directory")

    args = parser.parse_args(argv)

    # figure out where to put the csv
    name = os.path.basename(args.nc_file)
    if re.search("[.]nc$", name):
        name = re.sub("[.]nc", ".csv", name)
    else:
        name = "%s.nc" % name
    csv_path = os.path.join(args.working_dir, name)

    # return the file if it already exists
    if os.path.exists(csv_path):
        stdout.write(csv_path)
        return

    # otherwise, open the file for writing
    handle = open(csv_path, 'w+')
    write_csv(handle, args.nc_file, args.input)
    handle.close()

    stdout.write(csv_path)


def write_csv(handle, nc_file, input_file):
    # parse the netcdf file
    dataset = Dataset(nc_file)

    # find the data variable and latitude variable.
    data_variable = None
    data_variable_name = None
    lat_variable = None
    for key in dataset.variables:
        variable = dataset.variables[key]
        try:
            variable.quantity_type
            data_variable = variable
            data_variable_name = key

        except AttributeError:
            pass

        try:
            if variable.units == 'degrees_north':
                lat_variable = variable
        except AttributeError:
            pass

    if data_variable is None:
        raise AttributeError(
            "Unable to find data variable in netcdf file %s" % nc_file)
    if lat_variable is None:
        raise AttributeError(
            "Unable to find latitude variable in netcdf file %s" % nc_file)

    _write_header(handle, dataset, data_variable, input_file)
    handle.write("\n")
    _write_data(handle, lat_variable, data_variable, data_variable_name)

    dataset.close()


def _write_data(handle, lat_variable, data_variable, data_variable_name):
    handle.write("latitude (degrees north),%s\n" % data_variable_name)

    # Force the values to a masked array. Otherwise, variables without fill
    # values will be ndarray objects.
    data_values = np.ma.masked_array(data_variable[:])

    for i in range(data_variable.shape[0]):
        handle.write("%s,%s\n" % (lat_variable[i], data_values.data[i]))


def _write_header(handle, dataset, data_variable, input_file):
    # get out the title from the netcdf file
    title = dataset.title
    handle.write('Title:,"%s"\n' % title.strip())

    # parse the input file for the rest of the header
    input_xml = etree.parse(input_file)

    try:
        user_start_date = input_xml.xpath(r"/input/starttime")[0].text
        handle.write('User Start Date:,%s\n' % user_start_date)
    except IndexError:
        pass

    try:
        user_end_date = input_xml.xpath(r"/input/endtime")[0].text
        handle.write('User End Date:,%s\n' % user_end_date)
    except IndexError:
        pass

    try:
        bboxNodes = input_xml.xpath(r"/input/bbox")[0].text
        bbox = bboxNodes.replace("%2C", ",")
        handle.write('Bounding Box:,"%s"\n' % bbox)
    except IndexError:
        pass

    # form the service URL
    try:
        referer = input_xml.xpath(r"/input/referer")[0].text
        query = input_xml.xpath(r"/input/query")[0].text
        # we want everything except the 'session' part of the query
        parsed = urlparse.parse_qsl(query, True)
        keep = []
        for element in parsed:
            # check to see if this is 'session'
            if element[0] != 'session':
                keep.append(element)
        query = urllib.urlencode(keep)

        url = "%s#%s" % (referer, query)
        handle.write('URL to Reproduce Results:,"%s"\n' % url)
    except IndexError:
        pass

    fillvalue = data_variable._FillValue
    handle.write("Fill Value:,%s\n" % fillvalue)

if __name__ == "__main__":
    main(sys.argv[1:], sys.stdout)
