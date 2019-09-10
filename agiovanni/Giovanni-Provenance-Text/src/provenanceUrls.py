#!/bin/env python
# $Id: provenanceUrls.py,v 1.6 2015/02/04 17:02:48 dedasilv Exp $
# -@@@ Giovanni, Version $Name:  $

'''
NAME
provenanceUrls.py - writes all the output node text to a text file. Writes a 
suggested name for this provenance to stdout.


SYNOPSIS
provenanceUrls.py --dir /path/to/session --step "nameOfStep" \
  --out /path/to/out.txt \
  --lookup '/var/tmp/www/TS2/giovanni=>http://s4ptu-ts2.ecs.nasa.gov/WWW-TMP/giovanni'


OPTIONS
              --dir - the location of the session directory with provenance files
             --step - the step name filter for provenance files
              --out - output file name with all the outputs
           --lookup - conversions for file paths. Should be in the format 
                      '<path>=><url>'. If there is more than one conversion, use
                      more than one '--lookup'.
    --windowsOutput - if present, will use '\r\n' for end of line
    
AUTHORS
Christine Smit

VERSION
$REVISION:$
'''

import os;
import optparse;
import sys;
from lxml import etree
import re;
import hashlib;

def main(args):
    '''
    Looks for provenance files, gets their outputs, and writes them to a file.
    Writes a good name for the provenance file to stdout.
    '''
    # parse command line options
    parser = optparse.OptionParser(); 
    parser.add_option("--dir", dest="directory", help="session directory"); 
    parser.add_option("--step", dest="step", help="step name"); 
    parser.add_option("--out", dest="outFile", help="output file");
    parser.add_option("--lookup", dest="lookup", action="append", \
                      help="url lookups");
    parser.add_option("--windowsOutput", dest="windowsOutput", \
                      action="store_true", default=False, \
                      help="use windows-style end-of-line");
    
    (options, _) = parser.parse_args(args);
    
    if(not getattr(options, "directory", None)):
        raise ValueError("--dir is a required argument");
    
    if (not getattr(options, "step", None)):
        raise ValueError("--step is a required argument");
    
    if (not getattr(options, "outFile", None)):
        raise ValueError("--out is a required argument");
    
    if (not getattr(options, "lookup", None)):
        raise ValueError("--lookup is a required argument");
    
    if(options.windowsOutput):
        endOfLine = "\r\n";
    else:
        endOfLine = "\n";
    
    # parse the lookup
    lookup = {};
    for lookupStr in options.lookup:
        pieces = lookupStr.split("=>");
        if(len(pieces) != 2):
            raise ValueError("--lookup option needs arguments of the form 'path=>url'");
        lookup[pieces[0]] = pieces[1];
    
    
    # get the provenance files in the directory
    pattern = re.compile("^prov[.].*[.]xml$");
    provFilenames = [f for f in os.listdir(options.directory) \
                 if options.step in f and \
                 pattern.match(f) is not None];

    provFilenames = sorted(provFilenames)

    # open the output file
    f = open(options.outFile, 'w');
    
    
    
    # loop through provenance files
    for provFilename in provFilenames:
        root = etree.parse(os.path.join(options.directory, provFilename));
        # find the output nodes
        outputs = root.xpath("//output");
        for output in outputs:
            if output.get("TYPE") == "FILE" and ("/var/giovanni/session/" in output.text):
                # if this is a FILE, and it contains an absolute PATH, it
                # needs to be converted to a URL
                f.write(convertPathToUrl(lookup, output.text) + endOfLine);
            elif output.get("TYPE") == "FILE" and (options.directory not in output.text): 
                # if this file does not contain a relative or absolute PATH, 
                # it needs to be converted to a URL, so get the absolute PATH
                # and convert to an absolute URL
                output.text = os.path.join(options.directory, output.text)
                f.write(convertPathToUrl(lookup, output.text) + endOfLine);
            else:
                # otherwise, it's not a FILE and we just send it out as is
                f.write(output.text + endOfLine);

    f.close();
    os.chmod(options.outFile, 0664);
    print createFilename(provFilenames);

def createFilename(provFilenames):
    '''
    What we basically want to do here is combine the incoming names into one
    long name with nothing repeated. So, if the provenance files are:
    
        prov.algorithm+sINTERACTIVE_MAP+dMOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean+zNA+t20030101000000_20030131235959+b180.0000W_90.0000S_180.0000E_90.0000N.xml
        prov.algorithm+sINTERACTIVE_MAP+dMYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean+zNA+t20030101000000_20030131235959+b180.0000W_90.0000S_180.0000E_90.0000N.xml
    
    we're going to create a new filename:
    
        prov.algorithm+sINTERACTIVE_MAP+dMOD08_D3_051_Optical_Depth_Land_And_Ocean_Mean+zNA+dMYD08_D3_051_Optical_Depth_Land_And_Ocean_Mean+zNA+t20030101000000_20030131235959+b180.0000W_90.0000S_180.0000E_90.0000N.txt
    '''
    if(len(provFilenames) == 0):
        return;
    # get all the stuff between the first '+' and the '.xml'
    filenamePattern = re.compile("prov[.].*?[+](.*)[.]xml");
    
    # keep a dictionary of the different kinds of pieces
    bitsDictionary = {};
    keys = ['s', 'd', 't', 'b', 'g'];
    for key in keys:
        # we don't want duplicates, so make this a set
        bitsDictionary[key] = set()
    
    for provFilename in provFilenames:
        groups = filenamePattern.match(provFilename);
        # get the first match - the stuff between 'prov.' and '.xml'
        inner = groups.group(1);
        
        # We want to break up this inner stuff by '+', but we don't want the
        # split the +z sections away from the +d variables. So, just
        # temporarily subsitute something for the '+z'. 
        parsable = inner.replace("+z", "%z");
        
        bits = parsable.split("+");
        for bit in bits:
            key = bit[0];
            if(key in bitsDictionary):
                bitsDictionary[key].add(bit);            
        
        
    filename = "";
    for key in keys:
        if bitsDictionary[key]:
            combined = reduce(lambda x, y:x + "+" + y, bitsDictionary[key]);
            filename = filename + "+" + combined;
    
    # put back the '+z'
    filename = filename.replace("%z", "+z");
    # figure out what the start of the file should be
    start = re.match("(prov[.].*?)[+].*[.]xml", provFilenames[0]);
    filename = start.group(1) + filename + ".txt";
    
    if(len(filename) > 500):
        # too long! Just use an md5 hash of the stuff between 'prov.' and '.xml'
        middle = re.match("prov[.](.*)[.]txt", filename);
        m = hashlib.md5();
        m.update(middle.group(1));
        filename = "prov." + m.hexdigest() + ".txt";        
        
    return filename;

def convertPathToUrl(lookup, path):
    '''
    Converts a file path into a URL using the lookup dictionary.
    '''
    for key in lookup.keys():
        if key in lookup:
            return path.replace(key, lookup[key]);
    
    raise Exception("Unable to convert path to URL: " + path);

if __name__ == '__main__':
    main(sys.argv)




 

    
