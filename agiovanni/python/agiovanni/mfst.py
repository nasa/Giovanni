"""
A collection of functions for reading and writing manifest files.
"""
__author__ = 'Daniel da Silva <Daniel.daSilva@nasa.gov>'

import xml.etree.ElementTree as ET


def read_file_list(mfst_file_path):
    """Read the file list from a manifest file.
    
    Args
      mfst_file_path, the path to the manifest file
    Returns
      (id, files), files is a list of files on the system and id is
      the id associated with them.
    Raises
      IOError, error accessing the file
    """
    tree = ET.parse(mfst_file_path)
    root = tree.getroot()

    file_list = root.find('fileList')
    file_nodes = root.findall('fileList/file')

    return (file_list.attrib['id'],
            [file_node.text for file_node in file_nodes])


def write_file_list(mfst_file_path, file_list_id, file_list):
    """Write a file list to a manifest file.
    
    Overwrites the file if it already exists.
    
    Args
      mfst_file_path, the path to the manifest file to write
      file_list_id, 'id' attribute of the <fileList> element
      file_list, list of strings containing file names
    Raises
      IOError, error writing to the file
    """
    xml_lines = []
    xml_lines.append('<?xml version="1.0"?>')
    xml_lines.append('<manifest>')
    xml_lines.append('<fileList id="%s">' % file_list_id)

    for file_name in file_list:
        xml_lines.append('<file>%s</file>' % file_name)
    
    xml_lines.append('</fileList>')
    xml_lines.append('</manifest>')
    
    xml = '\n'.join(xml_lines)
    
    fh = open(mfst_file_path, 'w')
    fh.write(xml)
    fh.close()
    
