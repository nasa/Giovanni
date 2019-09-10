#! /bin/env python

"""
Calls two provided AESIRs and compares the resulting output for a single variable.

Example 1:
python compare2Aesirs.py --a1 https://aesir.gsfc.nasa.gov/aesir_solr/TS1 --a2 https://aesir.gsfc.nasa.gov/aesir_solr/OPS -v SWDB_L3M10_004_angstrom_exponent_stddev_land_ocean -e none
(will diff all tags in AESIR)

Example 2:
foreach f (`cat aesir.list |sort`)
      python compare2Aesirs.py --a1 https://aesir.gsfc.nasa.gov/aesir_solr/TS1 --a2 https://aesir.gsfc.nasa.gov/aesir_solr/OPS -v $f   >> primary.result
      python compare2Aesirs.py --a1 https://aesir.gsfc.nasa.gov/aesir_solr/OPS --a2 https://aesir.gsfc.nasa.gov/aesir_solr/TS1 -v $f   >> secondary.result
end
(will diff all tags but those 23 found in the default exclude list)
(this list can be obtained with something like: 
wget "https://aesir.gsfc.nasa.gov/aesir_solr/OPS/select?rows=40000&indent=on&q=dataFieldActive:true&fl=dataFieldId,dataFieldTimeIntvRepPos" -O aesir.active.ops.xml

Example 3:
python compare2Aesirs.py --a1 https://aesir.gsfc.nasa.gov/aesir_solr/TS1 --a2 https://aesir.gsfc.nasa.gov/aesir_solr/OPS -v SWDB_L3M10_004_angstrom_exponent_stddev_land_ocean -e my.file
(will diff all tags in but those appearing in 'my.file')

the exclude list,  involked with -e, can be utilized in 3 ways:
 1. leave out the -e   and you will use the default list of about 25 AESIR items that we originally thought wouldn't matter.
 2. -e none,           sets the exclude list to have one item: 'none' (provided you don't have a file present called 'none'
 3  -e filename        sets the exclude list to what is in <filename>. format of this file is one item per line
The exclude list tells the code not to worrry about those differences. See the code's default list for an idea.

Note: tested with /opt/anaconda/bin/python on dev

"""

import urllib2
import sys
import re
import optparse
from lxml import etree

__author__ = "Richard Strub richard.strub@nasa.gov"


def parse_cli_args(args):
    """Parses command line arguments.

    Returns
      options, an object whose attributes match the values of the
      specified in the command line. e.g. '-e xyz' <=> cli_opts.e
    Raises
      OptionError, error parsing options
      ValueError, invalid or missing argument
    """
    parser = optparse.OptionParser()

    parser.add_option("--a1", metavar="original", dest="a1",
                      help="original or primary aesir)")
    parser.add_option("--a2", metavar="compared", dest="a2",
                      help="the second or alternate aesir being compared with)")
    parser.add_option("-v", metavar="VARIABLE", dest="v",
                      help="Variable name being queried in both aesirs")
    parser.add_option("-e", metavar="exclude", dest="e",
                      help="csv list on command line or filename or 'none' - optional argument")

    cli_opts, _ = parser.parse_args(args)

    # Verify required are present and not empty
    for required_opt in ("a1", "a2", "v"):
        if not getattr(cli_opts, required_opt, None):
            parser.print_help()
            raise ValueError("-%s missing" % required_opt)

    return cli_opts


class AesirXml:

    def __init__(self):
        self.current = None
        self.index = 0
        self.mydict = {}

    # Recursively go through all the nodes in the XML:
    def show_nodes(self, root, depth, compare):
        if root is not None:
            for child in root.iterchildren():

                # get xpath of this current location
                xpath2here = self.getParent(child, "")

                if (len(xpath2here) > 0):
                    contrasts = compare.xpath(xpath2here)

                    # special handling for array headers:
                    if (re.match("^.*/arr$", xpath2here)):
                        self.current = child.attrib['name']
                        self.mydict[child.attrib['name']] = []

                    # special handling for each array item
                    elif (re.match("^.*/arr/.*$", xpath2here)):
                        # print "array item" , child.text
                        self.mydict[self.current].append(child.text)

                    # nominal handling for single items with 'name' attributes:
                    else:
                        if 'name' in child.keys():
                            this = {child.attrib['name']: child.text}
                            self.mydict.update(this)

                self.show_nodes(child, depth + 1, compare)

    def getParent(self, node, path):
        path = ""
        steps = []
        while node.getparent() is not None:
            steps.append(node.tag)
            node = node.getparent()

        steps.reverse()
        if (steps is None):
            return path

        for step in steps:
            path += "/" + step

        return '/response' + path



def handleExclude(option):
    # default list:
    exclude = [
        'dataFieldKeywords',
        'dataFieldKeywordsText',
        'dataFieldKeywordsString',
        'QTime',
        'sswBaseSubsetUrl',
        '_version_',
        'dataFieldLastIndexed',
        'dataFieldLastIndexed',
        'dataFieldGcmdEntryId',
        'dataFieldLastPublished',
        'dataFieldLastModified',
        'dataFieldSldUrl',
        'dataProductDescriptionUrl',
        'dataFieldLongNameText',
        'dataFieldValuesDistribution',
        'dataProductPlatformLongName',
        'dataFieldDiscipline',
        'dataProductProcessingLevel',
        'dataProductPlatformShortName',
        'dataProductInstrumentLongName',
        'dataFieldDescriptionUrl',
        'dataProductInstrumentShortName']
    hexclude = {}

    if option is not None:
        if re.match(".*,.*", option):
            exclude = option.split(",")
        else:
            exclude = []
            try:
                fh = open(option, 'r')
                exclude = fh.readlines()
                fh.close()
            except IOError:
                #sys.stderr.write("Could not open exclude file:" + option + " for read, assuming it is a single exclude option...\n")
                exclude.append(option)

    for elem in exclude:
        a = {elem.rstrip(): 1}
        hexclude.update(a)

    return hexclude


def format(array):

    output = ""
    #output = array[0] + "\n"

    for item in array:
           item = item.rstrip()
           if item == array[0]:
               output += "\n" + item
           else:
               output += "\n" + item
    return output


def handle_arrays(key, Primary_xml, Secondary_xml):

    output = []
    if (len(Primary_xml.mydict[key]) > 1):
        # even them up:
        Primary_xml.mydict[key].sort()

        # Secondary_xml might not actually exist:
        try:
            Secondary_xml.mydict[key].sort()
        except KeyError as e:
            output.append(
                format(
                    (key,'Secondary has no items at all in', ' array')))
            return

        # diff each of the array elements, see which ones are not there:
        for i in range(0, len(Primary_xml.mydict[key])):

            # if Secondary array item doesn't exist just print it
            if (i >= len(Secondary_xml.mydict[key])):
                if Primary_xml.mydict[key][
                        i] is not None:  # otherwise they list is empty in both and so they are the same
                    output.append(
                        format(
                            (key,
                             Primary_xml.mydict[key][i],
                                " missing in Secondary")))  # only print if different
            else:
                # only print if different
                if (Primary_xml.mydict[key][i] !=
                        Secondary_xml.mydict[key][i]):
                    output.append(
                        format(
                            (key,
                             Primary_xml.mydict[key][i],
                                "  !=   ",
                                Secondary_xml.mydict[key][i])))

        return output


def handle_named_values(key, Primary_xml, Secondary_xml):

    output = []
    try:
        if Primary_xml.mydict[key] != Secondary_xml.mydict[key]:
            if Secondary_xml.mydict[
                    key] is not None and Primary_xml.mydict[key] is not None:
                output.append(
                    format(
                        (key,
                         Primary_xml.mydict[key],
                         '  !=  ',
                         Secondary_xml.mydict[key])))  # only print if different
            elif Primary_xml.mydict[key] is not None:
                output.append(
                    format(
                        (key,
                         Primary_xml.mydict[key],
                         " missing in Secondary")))
            elif Secondary_xml.mydict[key] is not None:
                output.append(
                    format(
                        (key,
                         Secondary_xml.mydict[key],
                         " missing in Primary")))
    except KeyError as e:
        if Primary_xml.mydict[
                key] is not None:  # then this means Secondary was empty
            output.append(
                format(
                    (key, "Secondary missing",
                     Primary_xml.mydict[key])))

    return output


def get_data(aesir, variable):
    url = aesir + '/select?q=dataFieldId:"' + variable + '"'
    xml = urllib2.urlopen(url)
    doc = etree.parse(xml)
    root = doc.getroot()
    return root


def main(argv):
    cli_opts = parse_cli_args(argv[1:])
    variable = cli_opts.v
    # primary
    aesir1 = cli_opts.a1
    # alternate
    aesir2 = cli_opts.a2
    hexclude = handleExclude(cli_opts.e)

    root_Primary = get_data(aesir1, variable)
    Primary_xml = AesirXml()
    # use the same tree for testing
    Primary_xml.show_nodes(root_Primary, 1, root_Primary)

    root_Secondary = get_data(aesir2, variable)
    Secondary_xml = AesirXml()
    # use the same tree for testing
    Secondary_xml.show_nodes(root_Secondary, 1, root_Secondary)

    output = []
    for key in Primary_xml.mydict:
        if key not in hexclude.keys():

            #  if type is array:
            if hasattr(Primary_xml.mydict[key], '__iter__'):
                data = handle_arrays(key, Primary_xml, Secondary_xml)
                if data is not None:
                    for item in data:
                        if item is not None:
                            output.append(item)

            else:
                data = handle_named_values(key, Primary_xml, Secondary_xml)
                # else: Primary is also empty so do nothingd
                if data is not None:
                    for item in data:
                        if item is not None:
                            output.append(item)

    if (len(output) > 0):
        sys.stdout.write(variable + ":")
        for line in output:
            if line is not None:
                if (len(line) > 0):
                    print  line

if __name__ == '__main__':
    main(sys.argv)
