#!/opt/anaconda/bin/python

import sys
import argparse
import os
import re
from lxml import etree
import urlparse
import urllib
import numpy as np
from netCDF4 import Dataset
import time as pytime
import glob


def main(argv, stdout):
    """
    Main function. Called:
       serialize_ints  /path/to/working/directory(session)
    Prints out the name of the csv file created to stdout.

    @author: Richard Strub  <richard.f.strub@nasa.gov>
    """

    description = """
    Provide a single combined .csv output for interannual time series files
    There may be many missing items in the resulting matrix.
    """
    parser = argparse.ArgumentParser(description=description)

    parser.add_argument(
        "input", type=str, help="full session path")

    args = parser.parse_args(argv)

    myXml = lookFor(args.input, 'mfst.combine')
    if myXml is None:
        sys.exit(1)

    input_xml_obj = etree.parse(myXml)
    files = parseOutFiles(input_xml_obj)
    months = parseOutMonths(input_xml_obj)

    csvFileName = buildCSVFilename(files, months)
    csv_path = os.path.join(args.input, csvFileName)

    # return the file if it already exists
    if os.path.exists(csv_path):
        stdout.write(csv_path)
        return

    # otherwise, open the file for writing
    handle = open(csv_path, 'w+')
    write_csv(handle, files, months, args.input)
    handle.close()

    stdout.write(csv_path)


def buildCSVFilename(files, months):
    csv = ""
    monthstring = "-".join(months)

    if re.search("(.+)(MONTH.\d\d)\.(.+)", files[0]):
        csv = re.sub(r"MONTH.\d\d", monthstring, files[0])
        csv = re.sub(r".nc$", ".csv", csv)
    elif re.search("(.+)(SEASON.\w\w\w)\.(.+)", files[0]):
        csv = re.sub(r"SEASON.\w\w\w", monthstring, files[0])
        csv = re.sub(r".nc$", ".csv", csv)
    else:
        csv = 'combined.csv'

    return os.path.basename(csv)


def parseOutFiles(xmlobj):
    filenames = []
    files = xmlobj.xpath('/manifest/fileList/file')
    for file in files:
        filenames.append(file.text)
    return filenames


def parseOutMonths(xmlobj):
    months = []
    files = xmlobj.xpath('/manifest/fileList/file')
    for file in files:
        if re.search("(.+)(MONTH.\d\d)(.+)", file.text):
            months.append(re.match("(.+)(MONTH.\d\d)(.+)", file.text).group(2))
        elif re.search("(.+)(SEASON.\w\w\w)\.(.+)", file.text):
            months.append(
                re.match(
                    "(.+)SEASON.(\w\w\w)\.(.+)",
                    file.text).group(2))
        else:
            months.append('unknown')
    return months


def lookFor(sessionDir, prefix):
    pre = os.path.join(sessionDir, prefix + "*.xml")
    for file in glob.glob(pre):
        return file


# Here there is one 'month/season' for every filename
def write_csv(handle, nc_files, months, input_file):
    # parse the netcdf file
    datasets = []
    for nc_file in nc_files:
        datasets.append(Dataset(nc_file))

    # find the data variable and latitude variable.
    data_variable = None
    data_variable_name = None
    lat_bnds = None
    time = None
    data_variable_units = None

    i = 0
    # This nice code from serialize_zonal_mean is now in a loop since we
    # are combining output from more than one file:
    rows = {}
    for dataset in datasets:
        for key in dataset.variables:
            variable = dataset.variables[key]
            try:
                variable.quantity_type
                data_variable = variable
                data_variable_name = key
                data_variable_units = variable.units
                grid_bbox = build_gridinfo(dataset)

            except AttributeError:
                pass

            try:
                if variable.units == 'degrees_north':
                    lat_bnds = variable
            except AttributeError:
                pass

            try:
                if variable.units == 'degrees_east':
                    lon_bnds = variable
            except AttributeError:
                pass

            try:
                # This is the same logic as in the GUI, 
                # javascript code is sending HighCharts
                if variable.name == 'datayear':
                    if variable.dimensions[0] == 'time':
                        time = variable
            except AttributeError:
                pass

        if data_variable is None:
            raise AttributeError(
                "Unable to find data variable in netcdf file %s" % nc_file)
        if lat_bnds is None:
            raise AttributeError(
                "Unable to find latitude variable in netcdf file %s" % nc_file)

        # First time through write out the .csv 'metadata'
        if i == 0:
            _write_header(handle, dataset,
                          data_variable,
                          data_variable_name,
                          data_variable_units,
                          grid_bbox,  input_file)
        handle.write("\n")

        # writing out in rows necessitates having all the data together before writing out:
        # Using the MONTH/SEASON parsed from the filename is a safe way to designate the
        # canonical period
        # the time variable here is orthogonal to the MONTH/SEASON  - it is the list
        # of times(years) in 'this_month'
        _gather_data(time, data_variable, data_variable_name, rows, months[i])

        i = i + 1
        dataset.close()
    _write_data(handle, rows, months)


def build_gridinfo(dataset):
    west  =  dataset.geospatial_lon_min;
    east  =  dataset.geospatial_lon_max;
    south =  dataset.geospatial_lat_min;
    north =  dataset.geospatial_lat_max;

    return ",".join((west,south,east,north))

# So the difference is we are now putting the data in a hash so that
# we can accomodate missing values:
def _gather_data(time, data_variable, data_variable_name, rows, this_month):

    # Force the values to a masked array. Otherwise, variables without fill
    # values will be ndarray objects.
    data_values = np.ma.masked_array(data_variable[:])

    for i in range(data_values.size):
        if (len(data_values.shape) == 2):
            value = data_values.data[i][0]
        else:
            value = data_values.data[i]


        # Our data rows are always years
        year = time[i]

        if (year in rows):
            # overwriting, we expect only one value per month/year combo
            rows[year][this_month] = value  

        else:
            rows[year] = {this_month:value}


# So the difference is we are now writing data out from a hash so that
# we can arrange the data for missing values:
def _write_data(handle, rows, months):
    handle.write("TIME")
    for month in months:
        handle.write(",%s" % month)
    handle.write("\n")

    # year is the row
    for year in sorted(rows.keys()):
        handle.write("%s" % year)

        # month or season is the column
        for month in months:
            if month in rows[year]:
                handle.write(",%s" % rows[year][month])
            else:
                handle.write(",%s" % "  ")

        handle.write("\n")


def _write_header(handle, dataset, data_variable,
                  data_variable_name,
                  data_variable_units,
                  grid_bbox,
                  input_file):
    # get out the title from the netcdf file
    title = dataset.title
    handle.write('Title:,"%s"\n' % title.strip())

    # parse the input file for the rest of the header
    xmlfile = os.path.join(input_file, 'input.xml')
    input_xml = etree.parse(xmlfile)

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
        handle.write('User Bounding Box:,"%s"\n' % bbox)
        handle.write('Data Bounding Box:,"%s"\n' % grid_bbox)
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
    handle.write("Units:,%s\n" % data_variable_units)
    handle.write("Variable Name:,%s\n" % data_variable_name)

if __name__ == "__main__":
    main(sys.argv[1:], sys.stdout)
