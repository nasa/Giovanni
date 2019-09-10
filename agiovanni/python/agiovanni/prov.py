"""Functions to write provenance files.

This module provides a function for writing prov.$step_name.*.xml
files. Use the ProvItem class as a struct for holding information
about each provenance item.
"""
import os
import fnmatch
import xml.etree.ElementTree as ET
from lxml import etree
from datetime import datetime
from dateutil import parser


class ProvItem(object):
    """An immutable class that holds informatm about a provenance item.

    Attributes:
      file_path, text contents of the item element
      name, XML attribute "NAME" of the item element
      type_, XML attribute "TYPE" of the item element
    """

    def __init__(self, file_path, name='file', type_="FILE"):
        self.file_path = file_path
        self.name = name
        self.type_ = type_


def write_items(prov_file_path, elapsed_time, step_label,
                input_items, output_items):
    """Write a provenance XML file.

    Args
      prov_file_path, path to the provenance XML file. Usually
        something like prov.algorithm+[...].xml
      elapsed_time, time taken for the step to complete (seconds)
      step_label, display label for the step in the frontend
      input_items, list of ProvItem instances, <inputs>
      output_items, list of ProvItem instance, <outputs>
    """
    # Assert phase, check that all input and output files exist.
    for input_item in input_items:
        assert os.path.exists(input_item.file_path), \
            'Provenance input %s does not exist' % input_item.file_path
    for output_item in output_items:
        assert os.path.exists(output_item.file_path), \
            'Provenance output %s does not exist' % output_item.file_path

    # Generate the XML by constructing a sequence of strings
    # where each string is a line.
    xml_lines = []
    xml_lines.append('<?xml version="1.0"?>')
    xml_lines.append('<step ELAPSED_TIME="%.6f" NAME="%s">'
                     % (float(elapsed_time), step_label))

    xml_lines.append('<inputs>')
    for input_item in input_items:
        xml_lines.append('<input NAME="%s" TYPE="%s">%s</input>'
                         % (input_item.name, input_item.type_,
                            input_item.file_path))
    xml_lines.append('</inputs>')

    xml_lines.append('<outputs>')
    for output_item in output_items:
        xml_lines.append('<output NAME="%s" TYPE="%s">%s</output>'
                         % (output_item.name, output_item.type_,
                            output_item.file_path))
    xml_lines.append('</outputs>')

    xml_lines.append('<messages/>')
    xml_lines.append('</step>')

    # Write XML to provided file name
    xml = '\n'.join(xml_lines)

    fh = open(prov_file_path, 'w')
    fh.write(xml)
    fh.close()


def write_workflow_queue_time(curr_time, outputDir):
    """Wrapper method to write a workflow queue wait time provenance file.
    (Note: This is symbolic to a step). First, we want to calculate how long
    the user has to wait in the workflow queue. We call this wait interval "ELAPSED_TIME".
    The way we calculate ELAPSED_TIME is to take the difference between the current time
    (time before the workflow started) and the "first time" in line 1 of session.log

    Args
      curr_time, current system time right before the workflow is run
      outputDir, path to the session directory where the session logs are written.
    """
    # This is the label attribute for the step in provenance
    PROV_STEP_LABEL = 'Workflow Queue Step'

    # Get the session log
    session_log_file_path = os.path.join(outputDir, "session.log")

    # if session log has not been generated yet raise RunTimeError
    if not os.path.isfile(session_log_file_path):
        # raise an exception because this should never happen
        raise RuntimeError

    # Read the first line of session log
    with open(session_log_file_path, 'r') as f:
        first_line = f.readline()

        # Get the first time from session.log
        # The time looks like:
        # 2018-05-08 15:34:20 - [INFO ] - Workflow - STATUS:INFO Launching
        # workflow
    first_time = parser.parse(first_line[0:19])

    if first_line == '':
        # if the log is empty, exit. The workflow did not launch so there is no
        # point in going any further here.
        exit(1)
    elapsed_time = curr_time - first_time
    elapsed_time = elapsed_time.total_seconds()

    if elapsed_time < 0:  # elapsed time could be negative, in a rare case, so we
        elapsed_time = 0  # set it to zero since we cant's have negative time.

    # parse the input file to get the data node
    xmlfile = os.path.join(outputDir, 'input.xml')
    input_xml = etree.parse(xmlfile)
    data_node = input_xml.xpath(r"/input/data")[0].text

    # This is the path and name of the provenance file
    prov_file = "prov.workflow_queue_info+d" + data_node + ".xml"
    prov_file_path = os.path.join(outputDir, prov_file)
    input_items = ""  # we don't need these so we are just passing empty strings
    output_items = ""

    # Final step is to write the provenance file
    write_items(prov_file_path, elapsed_time, PROV_STEP_LABEL,
                input_items, output_items)
